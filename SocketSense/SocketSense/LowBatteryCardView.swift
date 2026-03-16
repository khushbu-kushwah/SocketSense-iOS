import UIKit

// MARK: - Low Battery Card
class LowBatteryCardView: SSCardView {

    private let sectionLabel   = SSSectionLabel("LOW BATTERY ALERT")
    private let enableRow      = SSToggleRow(title: "Enable low battery alert", isOn: true)
    private let remindRow      = SSToggleRow(title: "Remind every 1% drop below threshold", isOn: false)
    private let thresholdLabel = SSTitleLabel("Alert when battery reaches 5%", size: 16, weight: .regular)
    private lazy var slider    = SSLabeledSlider(min: 1, max: 100, value: 5, minText: "1%", maxText: "100%")

    var onEnableChanged: ((Bool) -> Void)?
    var onRemindChanged: ((Bool) -> Void)?
    var onThresholdChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        enableRow.onChanged = { [weak self] on in self?.onEnableChanged?(on) }
        remindRow.onChanged = { [weak self] on in self?.onRemindChanged?(on) }

        slider.onValueChanged = { [weak self] value in
            let pct = Int(value)
            self?.thresholdLabel.text = "Alert when battery reaches \(pct)%"
            self?.onThresholdChanged?(pct)
        }

        let stack = UIStackView(arrangedSubviews: [
            sectionLabel, enableRow, remindRow, thresholdLabel, slider
        ])
        stack.axis = .vertical
        stack.spacing = 14

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    func configure(settings: SocketSenseSettings) {
        enableRow.setOn(settings.isLowBatteryAlertEnabled)
        remindRow.setOn(settings.remindEvery1PercentDrop)
        slider.slider.value = Float(settings.lowBatteryThreshold)
        thresholdLabel.text = "Alert when battery reaches \(settings.lowBatteryThreshold)%"
    }
}
