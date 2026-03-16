import UIKit

// MARK: - Sensitivity Card
class SensitivityCardView: SSCardView {

    private let sectionLabel = SSSectionLabel("SENSITIVITY")
    private let titleLabel   = SSTitleLabel("Alert if unplugged within 10 seconds", size: 16, weight: .regular)
    private lazy var slider  = SSLabeledSlider(min: 1, max: 30, value: 10, minText: "1s", maxText: "30s")

    var onSensitivityChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        slider.onValueChanged = { [weak self] value in
            let seconds = Int(value)
            self?.titleLabel.text = "Alert if unplugged within \(seconds) seconds"
            self?.onSensitivityChanged?(seconds)
        }

        let stack = UIStackView(arrangedSubviews: [sectionLabel, titleLabel, slider])
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

    func configure(seconds: Int) {
        slider.slider.value = Float(seconds)
        titleLabel.text = "Alert if unplugged within \(seconds) seconds"
    }
}
