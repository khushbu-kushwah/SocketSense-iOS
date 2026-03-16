import UIKit

// MARK: - Reliability Card
class ReliabilityCardView: SSCardView {

    private let sectionLabel = SSSectionLabel("RELIABILITY")
    private let bodyLabel    = SSBodyLabel("For best reliability, disable battery optimization so iOS doesn't kill this app in the background.", size: 13)
    private let statusButton = SSPrimaryButton(title: "✓ BACKGROUND APP REFRESH")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        statusButton.backgroundColor = .ssAccentBlue.withAlphaComponent(0.8)
        statusButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [sectionLabel, bodyLabel, statusButton])
        stack.axis = .vertical
        stack.spacing = 12

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    @objc private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Alert Sound Card
class AlertSoundCardView: SSCardView {

    private let sectionLabel    = SSSectionLabel("ALERT SOUND")
    private let currentSoundLbl = SSBodyLabel("Using default alarm sound")
    private let chooseButton    = SSPrimaryButton(title: "CHOOSE AUDIO FILE")

    var onChooseAudio: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        chooseButton.addTarget(self, action: #selector(chooseTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [sectionLabel, currentSoundLbl, chooseButton])
        stack.axis = .vertical
        stack.spacing = 12

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    func configure(soundName: String) {
        currentSoundLbl.text = soundName == "default" ? "Using default alarm sound" : soundName
    }

    @objc private func chooseTapped() { onChooseAudio?() }
}

// MARK: - How It Works Footer
class HowItWorksView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        let label = SSBodyLabel(
            "How it works: When you plug in your charger, SocketSense starts a timer. " +
            "If the charger is removed before your set threshold, it assumes you forgot " +
            "to switch on the power socket — and plays an alert sound.",
            size: 13
        )
        label.textAlignment = .center
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
