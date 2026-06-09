//
//  OWMRegistrationViewController.swift
//  OpenBVKTracker
//
//  Scherm voor invoeren van OpenWeatherMap gratis API key.
//

import UIKit

protocol OWMRegistrationDelegate: AnyObject {
    func didSaveOWMApiKey(_ key: String)
}

class OWMRegistrationViewController: UIViewController {

    weak var delegate: OWMRegistrationDelegate?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let stepsLabel = UILabel()
    private let apiKeyField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)
    private let availableDataLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "OpenWeatherMap"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Sluiten", style: .plain, target: self,
            action: #selector(close))
        setupUI()
        apiKeyField.text = Preferences.shared.owmApiKey
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let padding: CGFloat = 20

        titleLabel.text = "OpenWeatherMap gratis account"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.numberOfLines = 0

        infoLabel.text = "Met een gratis OpenWeatherMap account kun je live weerkaartlagen tonen op de kaart. Geen creditcard nodig — 1.000.000 API calls per maand gratis."
        infoLabel.font = UIFont.systemFont(ofSize: 15)
        infoLabel.numberOfLines = 0
        infoLabel.textColor = .darkGray

        stepsLabel.text = "Stappen:\n1. Tik op 'Registreer gratis account'\n2. Maak een account aan op openweathermap.org\n3. Ga naar 'API keys' in je account\n4. Kopieer je API key en plak hem hieronder"
        stepsLabel.font = UIFont.systemFont(ofSize: 15)
        stepsLabel.numberOfLines = 0

        registerButton.setTitle("Registreer gratis account →", for: .normal)
        registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        registerButton.addTarget(self, action: #selector(openRegistration), for: .touchUpInside)

        apiKeyField.placeholder = "Plak hier je API key"
        apiKeyField.borderStyle = .roundedRect
        apiKeyField.font = UIFont(name: "Courier", size: 14) ?? UIFont.systemFont(ofSize: 14)
        apiKeyField.autocapitalizationType = .none
        apiKeyField.autocorrectionType = .no
        apiKeyField.clearButtonMode = .whileEditing

        saveButton.setTitle("Opslaan", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveKey), for: .touchUpInside)

        availableDataLabel.text = """
Beschikbare kaartlagen (gratis):

• Neerslag — actuele regen en sneeuw
• Bewolking — wolkendek in %
• Wind — windsnelheid op 10m hoogte
• Luchtdruk — oppervlaktedruk hPa
• Temperatuur — luchttemperatuur

Selecteer een laag via Instellingen → Kaartbron → OWM laag.
Kaart wordt elke 10 minuten ververst.
"""
        availableDataLabel.font = UIFont.systemFont(ofSize: 14)
        availableDataLabel.numberOfLines = 0
        availableDataLabel.textColor = .darkGray
        availableDataLabel.backgroundColor = UIColor(white: 0.95, alpha: 1)
        availableDataLabel.layer.cornerRadius = 8
        availableDataLabel.clipsToBounds = true

        let labelPadding = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        availableDataLabel.layoutMargins = labelPadding

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, infoLabel, stepsLabel, registerButton, apiKeyField, saveButton, availableDataLabel
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            apiKeyField.heightAnchor.constraint(equalToConstant: 44),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func openRegistration() {
        let url = URL(string: "https://home.openweathermap.org/users/sign_up")!
        UIApplication.shared.open(url)
    }

    @objc private func saveKey() {
        guard let key = apiKeyField.text?.trimmingCharacters(in: .whitespaces), !key.isEmpty else {
            let alert = UIAlertController(title: "Lege key", message: "Voer een geldige API key in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        Preferences.shared.owmApiKey = key
        delegate?.didSaveOWMApiKey(key)
        let alert = UIAlertController(title: "Opgeslagen", message: "API key opgeslagen. Selecteer nu een kaartlaag in de instellingen.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in self.close() })
        present(alert, animated: true)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
