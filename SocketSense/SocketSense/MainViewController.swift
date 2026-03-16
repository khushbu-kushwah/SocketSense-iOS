import UIKit
import Combine
import UniformTypeIdentifiers

// MARK: - Main View Controller
class MainViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = MainViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    // MARK: - UI Elements
    private let scrollView    = UIScrollView()
    private let contentStack  = UIStackView()
    private let headerView    = UIView()
    private let shieldIcon    = UIImageView()
    private let appNameLabel  = SSTitleLabel("SocketSense", size: 26)
    private let statusLabel   = SSBodyLabel("Monitoring Active")
    private let monitorToggle = UISwitch()

    // Cards
    private let statusCard      = StatusCardView()
    private let sensitivityCard = SensitivityCardView()
    private let lowBatteryCard  = LowBatteryCardView()
    private let reliabilityCard = ReliabilityCardView()
    private let alertSoundCard  = AlertSoundCardView()
    private let footerView      = HowItWorksView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ssBackground
        setupScrollView()
        setupHeader()
        setupCards()
        bindViewModel()
        startMonitoring()
        startUIRefresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateStatusCard()
    }

    // MARK: - ScrollView
    private func setupScrollView() {
        scrollView.backgroundColor = .ssBackground
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = .ssBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false

        // Shield icon
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)
        shieldIcon.image = UIImage(systemName: "checkmark.shield.fill", withConfiguration: config)
        shieldIcon.tintColor = .ssGreen
        shieldIcon.contentMode = .scaleAspectFit
        shieldIcon.translatesAutoresizingMaskIntoConstraints = false
        shieldIcon.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shieldIcon.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // Labels
        statusLabel.text = "Monitoring Active"
        statusLabel.textColor = .ssGreen
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)

        monitorToggle.isOn = viewModel.isMonitoringEnabled
        monitorToggle.onTintColor = .ssAccentBlue
        monitorToggle.addTarget(self, action: #selector(monitoringToggled), for: .valueChanged)

        let textStack = UIStackView(arrangedSubviews: [appNameLabel, statusLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let hStack = UIStackView(arrangedSubviews: [shieldIcon, textStack, spacer, monitorToggle])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),
            hStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 4),
            hStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -4)
        ])

        contentStack.addArrangedSubview(headerView)
    }

    // MARK: - Cards
    private func setupCards() {
        [statusCard, sensitivityCard, lowBatteryCard, reliabilityCard, alertSoundCard, footerView]
            .forEach { contentStack.addArrangedSubview($0) }

        sensitivityCard.configure(seconds: viewModel.settings.sensitivitySeconds)
        sensitivityCard.onSensitivityChanged = { [weak self] seconds in
            self?.viewModel.updateSensitivity(seconds)
        }

        lowBatteryCard.configure(settings: viewModel.settings)
        lowBatteryCard.onEnableChanged    = { [weak self] on  in self?.viewModel.toggleLowBatteryAlert(on) }
        lowBatteryCard.onRemindChanged    = { [weak self] on  in self?.viewModel.toggleRemindEveryPercent(on) }
        lowBatteryCard.onThresholdChanged = { [weak self] pct in self?.viewModel.updateLowBatteryThreshold(pct) }

        alertSoundCard.configure(soundName: viewModel.settings.alertSoundName)
        alertSoundCard.onChooseAudio = { [weak self] in self?.showAudioFilePicker() }
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$isMonitoringEnabled.receive(on: RunLoop.main).sink { [weak self] enabled in
            self?.monitorToggle.setOn(enabled, animated: true)
            self?.statusLabel.text  = enabled ? "Monitoring Active" : "Monitoring Paused"
            self?.statusLabel.textColor = enabled ? .ssGreen : .ssTextSecondary
        }.store(in: &cancellables)
    }

    // MARK: - Refresh
    private func startMonitoring() {
        ChargingMonitorService.shared.startMonitoring()
    }

    private func startUIRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.updateStatusCard() }
        }
    }

    private func updateStatusCard() {
        viewModel.refreshStatus()
        statusCard.update(vm: viewModel)
    }

    // MARK: - Actions
    @objc private func monitoringToggled() {
        viewModel.toggleMonitoring(monitorToggle.isOn)
    }

    private func showAudioFilePicker() {
        let types: [UTType] = [.audio, .mp3, .mpeg4Audio]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    deinit { refreshTimer?.invalidate() }
}

// MARK: - Document Picker Delegate
extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let destURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.copyItem(at: url, to: destURL)
        viewModel.updateAlertSound(url.lastPathComponent)
        alertSoundCard.configure(soundName: url.lastPathComponent)
    }
}
