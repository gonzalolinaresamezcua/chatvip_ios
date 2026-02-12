//
//  ChatBubble.swift
//  ChatVIP
//

import SwiftUI

struct ChatBubble: View {
    let message: Message
    let filesBaseURL: URL
    @ObservedObject var audioController: AudioPlayerController
    var onDelete: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil
    var onViewZoom: (() -> Void)? = nil
    var onCopyText: (() -> Void)? = nil

    private var backgroundColor: Color {
        switch message.type {
        case .USER: return Color(red: 0.3, green: 0.69, blue: 0.31)
        case .AI: return Color(red: 0.88, green: 0.88, blue: 0.88)
        case .SYSTEM: return Color.clear
        }
    }

    private var textColor: Color {
        switch message.type {
        case .USER: return .white
        case .AI, .SYSTEM: return .black
        }
    }

    private func resolveFileURL(_ relativePath: String) -> URL {
        relativePath.split(separator: "/").reduce(filesBaseURL) { $0.appendingPathComponent(String($1)) }
    }

    var body: some View {
        HStack {
            if message.type == .USER { Spacer(minLength: 40) }

            VStack(alignment: message.type == .SYSTEM ? .center : (message.type == .USER ? .trailing : .leading), spacing: 4) {
                bubbleContent
            }
            .padding(12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contextMenu {
                if message.contentType == .image {
                    Button("Ver / Zoom") { onViewZoom?() }
                    Button("Guardar en galería") { onSave?() }
                } else if message.contentType == .audio {
                    Button("Reproducir") {
                        let file = resolveFileURL(message.content)
                        audioController.playOrPause(file: file, messageId: message.id)
                    }
                    Button("Guardar") { onSave?() }
                } else {
                    Button("Copiar") { onCopyText?() }
                }
                Button("Eliminar", role: .destructive) { onDelete?() }
            }

            if message.type == .AI || message.type == .SYSTEM { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.contentType {
        case .image:
            let fileURL = resolveFileURL(message.content)
            if FileManager.default.fileExists(atPath: fileURL.path),
               let uiImage = UIImage(contentsOfFile: fileURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 300)
                    .onTapGesture { onViewZoom?() }
            } else {
                HStack {
                    Image(systemName: "photo")
                    Text("Imagen no encontrada")
                        .font(.caption)
                }
                .foregroundColor(textColor)
            }
        case .audio:
            if audioController.currentPlayingMessageId == message.id {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Button {
                            let file = resolveFileURL(message.content)
                            audioController.playOrPause(file: file, messageId: message.id)
                        } label: {
                            Image(systemName: audioController.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(textColor)
                        }
                        if audioController.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        }
                        Spacer()
                        Text("\(audioController.formatTime(audioController.currentPosition)) / \(audioController.formatTime(audioController.duration))")
                            .font(.caption)
                            .foregroundColor(textColor)
                    }
                    Slider(value: Binding(
                        get: { audioController.sliderPosition },
                        set: { audioController.seekTo($0) }
                    ), in: 0...1)
                }
                .frame(width: 200)
            } else {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("Nota de voz")
                        .font(.body)
                    Image(systemName: "play.circle")
                }
                .foregroundColor(textColor)
                .onTapGesture {
                    let file = resolveFileURL(message.content)
                    audioController.playOrPause(file: file, messageId: message.id)
                }
            }
        case .text:
            Text(message.content)
                .foregroundColor(textColor)
                .multilineTextAlignment(message.type == .SYSTEM ? .center : .leading)
        }
    }
}
