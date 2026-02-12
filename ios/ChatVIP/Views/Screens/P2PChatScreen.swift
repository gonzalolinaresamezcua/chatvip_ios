//
//  P2PChatScreen.swift
//  ChatVIP
//

import SwiftUI
import PhotosUI
import AVFoundation

struct P2PChatScreen: View {
    let peerPhone: String
    let onNavigateBack: () -> Void

    @StateObject private var viewModel: P2PChatViewModel
    @State private var imageFileToView: URL?
    private let storage = JsonStorage()
    private let mediaStorage = MediaStorage()

    init(peerPhone: String, onNavigateBack: @escaping () -> Void) {
        self.peerPhone = peerPhone
        self.onNavigateBack = onNavigateBack
        _viewModel = StateObject(wrappedValue: P2PChatViewModel(peerPhone: peerPhone))
    }

    private var peerDisplayName: String {
        storage.getContactName(peerPhone) ?? peerPhone
    }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        ZStack {
            ChatVIPBackground()
            VStack(spacing: 0) {
                header
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                messagesList
                MessageBar(
                    value: $viewModel.inputText,
                    onSend: { viewModel.sendMessage(viewModel.inputText) },
                    onPickImage: { viewModel.showImagePicker = true },
                    onRecordAudio: { viewModel.toggleRecording() },
                    isRecordingAudio: viewModel.isRecording,
                    enabled: true
                )
            }
        }
        .fullScreenCover(item: Binding(
            get: { imageFileToView.map { IdentifiableURL(url: $0) } },
            set: { imageFileToView = $0?.url }
        )) { item in
            FullScreenImageViewer(imageFile: item.url, onDismiss: { imageFileToView = nil })
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showImagePicker },
            set: { viewModel.showImagePicker = $0 }
        )) {
            PhotosPicker(
                selection: Binding(
                    get: { viewModel.selectedPhotoItem },
                    set: { viewModel.selectedPhotoItem = $0 }
                ),
                matching: .images
            ) {
                Text("Elegir imagen")
            }
            .photosPickerStyle(.inline)
            .onDisappear { viewModel.showImagePicker = false }
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data = data {
                    DispatchQueue.main.async {
                        viewModel.sendImage(data)
                        viewModel.selectedPhotoItem = nil
                        viewModel.showImagePicker = false
                    }
                }
            }
        }
        .onAppear {
            if let config = storage.loadP2PConfig() {
                viewModel.initChat(myPhone: config.phoneNumber, serverUrl: config.signalingServerUrl)
            }
        }
        .onDisappear { viewModel.cleanup() }
    }

    private var header: some View {
        HStack {
            Button(action: onNavigateBack) {
                Image(systemName: "chevron.left")
            }
            VStack(alignment: .leading) {
                Text(peerDisplayName)
                if storage.getContactName(peerPhone) != nil {
                    Text(peerPhone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button { viewModel.refreshFromServer() } label: {
                Image(systemName: "arrow.clockwise")
            }
            Text(viewModel.connectionState)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(viewModel.isConnecting ? Color.orange.opacity(0.3) : Color.green.opacity(0.3))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.messages) { msg in
                        ChatBubble(
                            message: msg,
                            filesBaseURL: documentsURL,
                            audioController: viewModel.audioController,
                            onDelete: { viewModel.deleteMessage(msg) },
                            onSave: {
                                let result: String? = {
                                    switch msg.contentType {
                                    case .image: return mediaStorage.saveImageToGallery(relativePath: msg.content)
                                    case .audio: return mediaStorage.saveAudioToDownloads(relativePath: msg.content)
                                    default: return nil
                                    }
                                }()
                                viewModel.showToast(result ?? "Error al guardar")
                            },
                            onViewZoom: {
                                let url = msg.content.split(separator: "/").reduce(documentsURL) { $0.appendingPathComponent(String($1)) }
                                if FileManager.default.fileExists(atPath: url.path) {
                                    imageFileToView = url
                                }
                            },
                            onCopyText: {
                                if msg.contentType == .text {
                                    UIPasteboard.general.string = msg.content
                                    viewModel.showToast("Copiado")
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let first = viewModel.messages.first {
                    withAnimation { proxy.scrollTo(first.id, anchor: .bottom) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
