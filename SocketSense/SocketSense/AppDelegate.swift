import UIKit
import UserNotifications
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 1. Register BG task FIRST before anything else
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.socketsense.monitor",
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            refreshTask.expirationHandler = {
                refreshTask.setTaskCompleted(success: false)
            }
            // Reschedule next refresh
            ChargingMonitorService.shared.scheduleBackgroundRefresh()
            refreshTask.setTaskCompleted(success: true)
        }

        // 2. Request notifications
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }

        // 3. Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true

        // 4. Setup window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor(red: 0.059, green: 0.067, blue: 0.090, alpha: 1)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()

        // 5. Start monitoring AFTER window is set up
        ChargingMonitorService.shared.startMonitoring()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        ChargingMonitorService.shared.scheduleBackgroundRefresh()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ SocketSense Stopped"
        content.body = "App was closed. Tap to restart charger monitoring."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "terminated",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}
