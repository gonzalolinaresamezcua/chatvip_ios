//
//  PhoneSetupScreen.swift
//  ChatVIP
//

import SwiftUI

struct PhoneSetupScreen: View {
    let onSetupComplete: () -> Void

    @State private var userName = ""
    @State private var phoneNumber = ""
    @State private var signalingUrl = P2PConfig.defaultServerUrl
    @State private var error: String?
    private let storage = JsonStorage()

    var body: some View {
        ZStack {
            ChatVIPBackground()
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    Text("Chat VIP")
                        .font(.title.bold())
                    Text("Identifícate con tu número de teléfono")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Nombre", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                    TextField("Número de teléfono", text: $phoneNumber)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                    TextField("Servidor de mensajes", text: $signalingUrl)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    if let err = error {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Button("Continuar") { saveAndContinue() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            VStack {
                Spacer()
                PoweredByFooter()
            }
        }
        .onAppear { loadConfig() }
    }

    private func loadConfig() {
        if let config = storage.loadP2PConfig() {
            userName = config.userName ?? ""
            phoneNumber = config.phoneNumber
            signalingUrl = config.signalingServerUrl
        }
    }

    private func formatPhone(_ input: String) -> String {
        let digits = input.filter { $0.isNumber || $0 == "+" }
        return digits.hasPrefix("+") ? digits : "+34\(digits)"
    }

    private func saveAndContinue() {
        let cleaned = formatPhone(phoneNumber)
        guard cleaned.count >= 10 else {
            error = "Introduce un número válido (ej: +34686522038)"
            return
        }
        storage.saveP2PConfig(P2PConfig(
            phoneNumber: cleaned,
            signalingServerUrl: signalingUrl,
            userName: userName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : userName.trimmingCharacters(in: .whitespaces)
        ))
        onSetupComplete()
    }
}
