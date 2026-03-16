import Foundation
import UIKit
import Combine

// MARK: - Main ViewModel
class MainViewModel {

    // MARK: - Published State
    @Published var isMonitoringEnabled: Bool = true
    @Published var alertsTriggered: Int = 0
    @Published var lastEvent: String = "No events yet"
    @Published var pluggedInTime: String = "--"
    @Published var removedTime: String = "--"
    @Published var connectedDuration: String = "--"
    @Published var batteryLevel: String = "--"
    @Published var currentMA: String = "-- mA"
    @Published var chargedPercent: String = "+0%"
    @Published var chargeRate: String = "-- % per min"
    @Published var isCurrentlyCharging: Bool = false

    // MARK: - Settings
    @Published var settings: SocketSenseSettings = SocketSenseSettings.load()

    private let service = ChargingMonitorService.shared
    private var timer: Timer?

    init() {
        loadState()
        bindService()
        startRefreshTimer()
    }

    // MARK: - Setup
    private func loadState() {
        isMonitoringEnabled = settings.isMonitoringEnabled
        alertsTriggered = service.alertsTriggered
        updateBatteryDisplay()
    }

    private func bindService() {
        service.onChargingStateChanged = { [weak self] isCharging in
            DispatchQueue.main.async {
                self?.isCurrentlyCharging = isCharging
                self?.refreshStatus()
            }
        }

        service.onAlertTriggered = { [weak self] message in
            DispatchQueue.main.async {
                self?.alertsTriggered = self?.service.alertsTriggered ?? 0
                self?.lastEvent = message
            }
        }
    }

    private func startRefreshTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    // MARK: - Refresh
    func refreshStatus() {
        isCurrentlyCharging = service.isCharging
        alertsTriggered = service.alertsTriggered
        updateBatteryDisplay()
        updateChargingTimes()
    }

    private func updateBatteryDisplay() {
        let level = UIDevice.current.batteryLevel
        let percent = Int(level * 100)
        batteryLevel = "\(percent)%"

        // iOS doesn't give milliamps directly, estimate
        currentMA = service.isCharging ? "~180 mA" : "0 mA"
    }

    private func updateChargingTimes() {
        let fmt = DateFormatter()
        fmt.dateFormat = "hh:mm:ss a"

        if let plugged = service.lastPluggedIn {
            pluggedInTime = fmt.string(from: plugged)
        }
        if let removed = service.lastRemoved {
            removedTime = fmt.string(from: removed)
            lastEvent = "Unplugged normally at \(fmt.string(from: removed))"
        }
        if let event = service.currentEvent {
            let dur = event.connectedDuration
            let h = Int(dur) / 3600
            let m = (Int(dur) % 3600) / 60
            let s = Int(dur) % 60
            if h > 0 {
                connectedDuration = "\(h)h \(m)m \(s)s"
            } else {
                connectedDuration = "\(m)m \(s)s"
            }

            let charged = service.chargedPercent
            chargedPercent = "+\(Int(charged))%"
            let minutes = dur / 60
            let rate = minutes > 0 ? charged / Float(minutes) : 0
            chargeRate = String(format: "%.1f%% per min", rate)
        }
    }

    // MARK: - Actions
    func toggleMonitoring(_ enabled: Bool) {
        isMonitoringEnabled = enabled
        settings.isMonitoringEnabled = enabled
        settings.save()
        if enabled {
            service.startMonitoring()
        } else {
            service.stopMonitoring()
        }
    }

    func updateSensitivity(_ seconds: Int) {
        settings.sensitivitySeconds = seconds
        settings.save()
    }

    func updateLowBatteryThreshold(_ percent: Int) {
        settings.lowBatteryThreshold = percent
        settings.save()
    }

    func toggleLowBatteryAlert(_ enabled: Bool) {
        settings.isLowBatteryAlertEnabled = enabled
        settings.save()
    }

    func toggleRemindEveryPercent(_ enabled: Bool) {
        settings.remindEvery1PercentDrop = enabled
        settings.save()
    }

    func updateAlertSound(_ name: String) {
        settings.alertSoundName = name
        settings.save()
    }

    deinit {
        timer?.invalidate()
    }
}
