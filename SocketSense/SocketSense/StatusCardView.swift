import UIKit

// MARK: - Status Card
class StatusCardView: SSCardView {

    // Labels
    private let sectionLabel  = SSSectionLabel("STATUS")
    private let alertsTitle   = SSTitleLabel("Alerts triggered: 0", size: 22)
    private let lastEventRow  = SSStatRow(emoji: "📋", value: "No events yet")
    private let pluggedInRow  = SSStatRow(emoji: "🔌", value: "--")
    private let removedRow    = SSStatRow(emoji: "🔴", value: "--")
    private let durationRow   = SSStatRow(emoji: "⏱", value: "--")
    private let batteryRow    = SSStatRow(emoji: "⚡", value: "--")
    private let chargedRow    = SSStatRow(emoji: "📊", value: "--")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            sectionLabel,
            alertsTitle,
            lastEventRow,
            SSDivider(),
            pluggedInRow,
            removedRow,
            durationRow,
            batteryRow,
            chargedRow
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(12, after: sectionLabel)
        stack.setCustomSpacing(8, after: alertsTitle)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    func update(vm: MainViewModel) {
        alertsTitle.text = "Alerts triggered: \(vm.alertsTriggered)"
        lastEventRow.setValue(vm.lastEvent)
        pluggedInRow.setValue(vm.pluggedInTime)
        removedRow.setValue(vm.removedTime)
        durationRow.setValue(vm.connectedDuration)
        batteryRow.setValue("\(vm.batteryLevel) · \(vm.currentMA)")
        chargedRow.setValue("\(vm.chargedPercent) at \(vm.chargeRate)")
    }
}
