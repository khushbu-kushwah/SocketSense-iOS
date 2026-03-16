import UIKit
import AVFoundation
import AudioToolbox
import BackgroundTasks
import UserNotifications

// MARK: - Charging Monitor Service
class ChargingMonitorService: NSObject {

    static let shared = ChargingMonitorService()

    var onChargingStateChanged: ((Bool) -> Void)?
    var onAlertTriggered: ((String) -> Void)?

    private var pluggedInTime: Date?
    private var silentPlayer: AVAudioPlayer?
    private var alarmPlayer: AVAudioPlayer?
    private(set) var currentEvent: ChargingEvent?
    private(set) var alertsTriggered: Int = 0
    private(set) var chargedPercent: Float = 0
    private var initialBatteryLevel: Float = 0
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var pollingTimer: Timer?
    private var lastKnownChargingState: Bool = false
    private var stateConfirmCount: Int = 0

    var lastPluggedIn: Date? { pluggedInTime }
    var lastRemoved: Date?
    var batteryLevel: Float { UIDevice.current.batteryLevel * 100 }
    var isCharging: Bool {
        UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }

    private override init() {
        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
        loadAlertCount()
    }

    // MARK: - Start Monitoring
    func startMonitoring() {
        setupAudioSession()
        startSilentAudio()
        startPollingTimer()
        registerObservers()

        lastKnownChargingState = isCharging
        if isCharging {
            pluggedInTime = Date()
            initialBatteryLevel = batteryLevel
        }
        print("SocketSense: Monitoring started. isCharging=\(isCharging)")
    }

    func stopMonitoring() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        silentPlayer?.stop()
        silentPlayer = nil
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
    }

    // MARK: - Background Refresh (called from AppDelegate)
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.socketsense.monitor")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("SocketSense: BG refresh schedule error: \(error)")
        }
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            print("SocketSense: Audio session active")
        } catch {
            print("SocketSense: Audio session error: \(error)")
        }
    }

    // MARK: - Silent Audio
    func startSilentAudio() {
        guard silentPlayer?.isPlaying != true else { return }
        guard let url = makeSilentWAV() else { return }
        do {
            silentPlayer = try AVAudioPlayer(contentsOf: url)
            silentPlayer?.numberOfLoops = -1
            silentPlayer?.volume = 0.01
            silentPlayer?.prepareToPlay()
            silentPlayer?.play()
            print("SocketSense: Silent audio playing")
        } catch {
            print("SocketSense: Silent audio error: \(error)")
        }
    }

    private func makeSilentWAV() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ss_silence.wav")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        var data = Data()
        let sr: Int32 = 8000
        let samples: Int32 = sr * 3
        let dataSize: Int32 = samples * 2
        let fileSize: Int32 = dataSize + 36
        func w<T>(_ v: T) { var x = v; data.append(Data(bytes: &x, count: MemoryLayout<T>.size)) }
        data.append("RIFF".data(using: .ascii)!); w(fileSize)
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!); w(Int32(16)); w(Int16(1)); w(Int16(1))
        w(sr); w(sr * 2); w(Int16(2)); w(Int16(16))
        data.append("data".data(using: .ascii)!); w(dataSize)
        data.append(Data(count: Int(dataSize)))
        try? data.write(to: url)
        return url
    }

    // MARK: - Polling Timer
    private func startPollingTimer() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollChargingState()
        }
        RunLoop.main.add(pollingTimer!, forMode: .common)
    }

    private func pollChargingState() {
        // Keep silent audio alive
        if silentPlayer?.isPlaying == false {
            startSilentAudio()
        }

        let current = isCharging
        if current != lastKnownChargingState {
            stateConfirmCount += 1
            if stateConfirmCount >= 2 {
                stateConfirmCount = 0
                lastKnownChargingState = current
                handleChargingChange(isNowCharging: current)
            }
        } else {
            stateConfirmCount = 0
        }
    }

    private func handleChargingChange(isNowCharging: Bool) {
        print("SocketSense: Charging → \(isNowCharging)")
        onChargingStateChanged?(isNowCharging)

        if isNowCharging {
            pluggedInTime = Date()
            initialBatteryLevel = batteryLevel
        } else {
            let removedAt = Date()
            lastRemoved = removedAt
            let settings = SocketSenseSettings.load()

            if let plugged = pluggedInTime {
                let duration = removedAt.timeIntervalSince(plugged)
                chargedPercent = batteryLevel - initialBatteryLevel
                currentEvent = ChargingEvent(pluggedInTime: plugged, removedTime: removedAt)
                print("SocketSense: Unplugged. Duration=\(Int(duration))s threshold=\(settings.sensitivitySeconds)s")

                if Int(duration) <= settings.sensitivitySeconds {
                    print("SocketSense: ALERT!")
                    triggerUnpluggedAlert()
                }
            }
            pluggedInTime = nil
        }
    }

    // MARK: - Observers
    private func registerObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(audioInterrupted),
            name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func batteryLevelChanged() {
        let settings = SocketSenseSettings.load()
        guard settings.isLowBatteryAlertEnabled else { return }
        let level = batteryLevel
        if !isCharging && level <= Float(settings.lowBatteryThreshold) {
            triggerLowBatteryAlert(level: level)
        }
    }

    @objc private func appDidEnterBackground() {
        print("SocketSense: Entered background. BG time: \(UIApplication.shared.backgroundTimeRemaining)s")
        startBackgroundTask()
    }

    @objc private func appWillEnterForeground() {
        print("SocketSense: Entered foreground")
        endBackgroundTask()
    }

    @objc private func audioInterrupted(_ n: Notification) {
        guard let info = n.userInfo,
              let val = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: val),
              type == .ended else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            try? AVAudioSession.sharedInstance().setActive(true)
            self?.startSilentAudio()
        }
    }

    // MARK: - Background Task
    private func startBackgroundTask() {
        endBackgroundTask()
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SocketSense") {
            [weak self] in self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // MARK: - Alerts
    private func triggerUnpluggedAlert() {
        alertsTriggered += 1
        saveAlertCount()
        sendNotification(title: "⚡ Charger Alert!",
                         body: "Charger removed before socket was switched on!")
        playAlarm()
        onAlertTriggered?("Charger unplugged too soon!")
    }

    private func triggerLowBatteryAlert(level: Float) {
        sendNotification(title: "🔋 Low Battery",
                         body: "Battery is at \(Int(level))%.")
        playAlarm()
        onAlertTriggered?("Low battery: \(Int(level))%")
    }

    func playAlarm() {
        silentPlayer?.stop()
        AudioServicesPlayAlertSound(SystemSoundID(1005))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

        let paths = ["/System/Library/Audio/UISounds/alarm.caf",
                     "/System/Library/Audio/UISounds/Tri-tone.caf"]
        for path in paths {
            if let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) {
                alarmPlayer = player
                alarmPlayer?.volume = 1.0
                alarmPlayer?.numberOfLoops = 5
                alarmPlayer?.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                    self?.alarmPlayer?.stop()
                    self?.startSilentAudio()
                }
                return
            }
        }
        startSilentAudio()
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical
        if #available(iOS 15.0, *) { content.interruptionLevel = .critical }
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        print("SocketSense: Notification sent — \(title)")
    }

    private func saveAlertCount() {
        UserDefaults.standard.set(alertsTriggered, forKey: "alertsTriggered")
    }
    private func loadAlertCount() {
        alertsTriggered = UserDefaults.standard.integer(forKey: "alertsTriggered")
    }
}
