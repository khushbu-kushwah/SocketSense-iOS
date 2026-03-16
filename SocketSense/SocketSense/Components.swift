import UIKit

// MARK: - Color Palette
extension UIColor {
    static let ssBackground    = UIColor(hex: "#0F1117")
    static let ssCardBg        = UIColor(hex: "#181C27")
    static let ssAccentBlue    = UIColor(hex: "#4C6EF5")
    static let ssGreen         = UIColor(hex: "#40C057")
    static let ssTextPrimary   = UIColor.white
    static let ssTextSecondary = UIColor(white: 1, alpha: 0.55)
    static let ssSectionLabel  = UIColor(white: 1, alpha: 0.38)

    convenience init(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexStr = hexStr.hasPrefix("#") ? String(hexStr.dropFirst()) : hexStr
        var rgb: UInt64 = 0
        Scanner(string: hexStr).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8)  & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF)         / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Card View
class SSCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .ssCardBg
        layer.cornerRadius = 16
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Section Label
class SSSectionLabel: UILabel {
    init(_ text: String) {
        super.init(frame: .zero)
        self.text = text.uppercased()
        font = .systemFont(ofSize: 11, weight: .semibold)
        textColor = .ssSectionLabel
        letterSpacing(1.2)
    }
    required init?(coder: NSCoder) { fatalError() }

    func letterSpacing(_ spacing: CGFloat) {
        attributedText = NSAttributedString(string: text ?? "",
                                            attributes: [.kern: spacing,
                                                         .font: font as Any,
                                                         .foregroundColor: textColor as Any])
    }
}

// MARK: - Title Label
class SSTitleLabel: UILabel {
    init(_ text: String = "", size: CGFloat = 20, weight: UIFont.Weight = .bold) {
        super.init(frame: .zero)
        self.text = text
        font = .systemFont(ofSize: size, weight: weight)
        textColor = .ssTextPrimary
        numberOfLines = 0
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Body Label
class SSBodyLabel: UILabel {
    init(_ text: String = "", size: CGFloat = 14) {
        super.init(frame: .zero)
        self.text = text
        font = .systemFont(ofSize: size, weight: .regular)
        textColor = .ssTextSecondary
        numberOfLines = 0
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Toggle Row
class SSToggleRow: UIView {
    let label = SSTitleLabel("", size: 16, weight: .regular)
    let toggle = UISwitch()
    var onChanged: ((Bool) -> Void)?

    init(title: String, isOn: Bool = false) {
        super.init(frame: .zero)
        label.text = title
        toggle.isOn = isOn
        toggle.onTintColor = .ssAccentBlue
        toggle.addTarget(self, action: #selector(toggled), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [label, UIView(), toggle])
        stack.axis = .horizontal
        stack.alignment = .center
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func toggled() { onChanged?(toggle.isOn) }

    func setOn(_ on: Bool) { toggle.setOn(on, animated: true) }
}

// MARK: - Primary Button
class SSPrimaryButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        backgroundColor = .ssAccentBlue
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        layer.cornerRadius = 12
        heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Labeled Slider
class SSLabeledSlider: UIView {
    let slider = UISlider()
    let minLabel: UILabel
    let maxLabel: UILabel
    var onValueChanged: ((Float) -> Void)?

    init(min: Float, max: Float, value: Float, minText: String, maxText: String) {
        minLabel = UILabel()
        maxLabel = UILabel()
        super.init(frame: .zero)

        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        slider.minimumTrackTintColor = .ssAccentBlue
        slider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.15)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        [minLabel, maxLabel].forEach {
            $0.font = .systemFont(ofSize: 12)
            $0.textColor = .ssTextSecondary
        }
        minLabel.text = minText
        maxLabel.text = maxText

        let labelsRow = UIStackView(arrangedSubviews: [minLabel, UIView(), maxLabel])
        labelsRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [slider, labelsRow])
        stack.axis = .vertical
        stack.spacing = 4

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func sliderChanged() { onValueChanged?(slider.value) }
}

// MARK: - Stat Row
class SSStatRow: UIView {
    private let emojiLabel = UILabel()
    private let valueLabel = UILabel()

    init(emoji: String, value: String = "--") {
        super.init(frame: .zero)
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 14)

        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .ssTextSecondary

        let stack = UIStackView(arrangedSubviews: [emojiLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ text: String) { valueLabel.text = text }
}

// MARK: - Divider
class SSDivider: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1, alpha: 0.08)
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
}
