import Foundation

// MARK: - Charging Event
struct ChargingEvent {
    let pluggedInTime: Date?
    let removedTime: Date?
    var connectedDuration: TimeInterval {
        guard let plugged = pluggedInTime, let removed = removedTime else { return 0 }
        return removed.timeIntervalSince(plugged)
    }
}

// MARK: - App Settings
struct SocketSenseSettings: Codable {
    var isMonitoringEnabled: Bool = true
    var sensitivitySeconds: Int = 10       // Alert if unplugged within N seconds
    var isLowBatteryAlertEnabled: Bool = true
    var lowBatteryThreshold: Int = 5       // percent
    var remindEvery1PercentDrop: Bool = false
    var alertSoundName: String = "default"

    static let `default` = SocketSenseSettings()

    static func load() -> SocketSenseSettings {
        guard let data = UserDefaults.standard.data(forKey: "SocketSenseSettings"),
              let settings = try? JSONDecoder().decode(SocketSenseSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "SocketSenseSettings")
        }
    }
}

// MARK: - Charging Status
enum ChargingStatus {
    case pluggedIn(Date)
    case unplugged(Date)
    case unknown
}

// MARK: - Alert Event
struct AlertRecord: Codable {
    let id: UUID
    let timestamp: Date
    let type: AlertType
    let batteryLevel: Float

    enum AlertType: String, Codable {
        case chargerUnplugged = "Charger unplugged too soon"
        case lowBattery = "Low battery warning"
    }
}
