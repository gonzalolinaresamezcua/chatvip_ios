//
//  MessageBar.swift
//  ChatVIP
//

import SwiftUI

struct MessageBar: View {
    @Binding var value: String
    let onSend: () -> Void
    var onPickImage: (() -> Void)? = nil
    var onRecordAudio: (() -> Void)? = nil
    var isRecordingAudio: Bool = false
    var enabled: Bool = true

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if let pickImage = onPickImage {
                Button(action: pickImage) {
                    Image(systemName: "photo")
                        .font(.title2)
                }
                .disabled(!enabled)
            }
            if let recordAudio = onRecordAudio {
                Button(action: recordAudio) {
                    Image(systemName: isRecordingAudio ? "stop.circle.fill" : "mic.fill")
                        .font(.title2)
                }
                .disabled(!enabled)
            }
            TextField("Escribe tu mensaje...", text: $value, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(!enabled)
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(value.isEmpty ? .gray : .accentColor)
            }
            .disabled(!enabled || value.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(8)
        .background(Color(.systemBackground))
    }
}
