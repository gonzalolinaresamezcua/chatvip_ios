//
//  P2PChatViewModel.swift
//  ChatVIP
//

import SwiftUI
import PhotosUI
import AVFoundation
import Combine

final class P2PChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var connectionState = "Desconectado"
    @Published var errorMessage: String?
    @Published var isConnecting = false
    @Published var isRecording = false
    @Published var toastMessage: String?
    @Published var showImagePicker = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    let audioController = AudioPlayerController()
    let peerPhone: String

    private let storage = JsonStorage()
    private let mediaStorage = MediaStorage()
    private var myPhone = ""
    private var serverUrl = ""
    private var cancellables = Set<AnyCancellable>()
    private var recorder: AVAudioRecorder?
    private var recordedURL: URL?

    init(peerPhone: String) {
        self.peerPhone = peerPhone
    }

    private func normalizePhone(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return digits.hasPrefix("+") ? digits : "+\(digits)"
    }

    private func conversationId() -> String {
        let sorted = [myPhone, peerPhone].sorted()
        return "p2p_\(sorted[0])_\(sorted[1])"
    }

    func initChat(myPhone: String, serverUrl: String) {
        self.myPhone = normalizePhone(myPhone)
        self.serverUrl = serverUrl
        GlobalMessageManager.shared.setCurrentChat(conversationId())
        loadLocalCache()
        MessageServerHolder.shared.connect(serverUrl: self.serverUrl, myPhone: self.myPhone)
        MessageServerHolder.shared.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.connectionState = $0.isEmpty ? "Desconectado" : $0
                self?.isConnecting = $0 == "Conectando..."
            }
            .store(in: &cancellables)
        GlobalMessageManager.shared.messageReceivedFlow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chatId, msg in
                if chatId == self?.conversationId() {
                    self?.addMessage(msg)
                }
            }
            .store(in: &cancellables)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            MessageServerHolder.shared.requestSync(since: "1970-01-01")
        }
    }

    private func loadLocalCache() {
        if let conv = storage.loadConversation(conversationId()) {
            messages = conv.messages.map { storage.jsonToMessage($0) }.reversed()
        }
    }

    func sendMessage(_ text: String) {
        let txt = text.trimmingCharacters(in: .whitespaces)
        guard !txt.isEmpty else { return }
        inputText = ""
        let tempId = "local_\(Int(Date().timeIntervalSince1970 * 1000))"
        let userMsg = Message(id: tempId, type: .USER, content: txt)
        addMessage(userMsg)
        saveMessageLocally(userMsg)
        if MessageServerHolder.shared.isConnected() {
            MessageServerHolder.shared.sendMessage(to: peerPhone, content: txt, contentType: "text")
        } else {
            errorMessage = "Sin conexión. Reconecta e inténtalo de nuevo."
        }
    }

    func sendImage(_ imageData: Data) {
        let path = mediaStorage.saveImage(imageData)
        let tempId = "local_\(Int(Date().timeIntervalSince1970 * 1000))"
        let userMsg = Message(id: tempId, type: .USER, content: path, contentType: .image)
        addMessage(userMsg)
        saveMessageLocally(userMsg)
        if MessageServerHolder.shared.isConnected() {
            let base64 = imageData.base64EncodedString()
            MessageServerHolder.shared.sendMessage(to: peerPhone, content: base64, contentType: "image")
        } else {
            errorMessage = "Sin conexión. Reconecta e inténtalo de nuevo."
        }
    }

    func sendAudio(_ audioData: Data) {
        let path = mediaStorage.saveAudio(audioData)
        let tempId = "local_\(Int(Date().timeIntervalSince1970 * 1000))"
        let userMsg = Message(id: tempId, type: .USER, content: path, contentType: .audio)
        addMessage(userMsg)
        saveMessageLocally(userMsg)
        if MessageServerHolder.shared.isConnected() {
            let base64 = audioData.base64EncodedString()
            MessageServerHolder.shared.sendMessage(to: peerPhone, content: base64, contentType: "audio")
        } else {
            errorMessage = "Sin conexión. Reconecta e inténtalo de nuevo."
        }
    }


    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("audio_\(UUID().uuidString).m4a")
            recordedURL = url
            recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1
            ])
            recorder?.record()
            isRecording = true
        } catch {
            errorMessage = "Error al grabar"
        }
    }

    private func stopRecording() {
        recorder?.stop()
        recorder = nil
        if let url = recordedURL, let data = try? Data(contentsOf: url) {
            sendAudio(data)
            try? FileManager.default.removeItem(at: url)
        }
        recordedURL = nil
        isRecording = false
    }

    private func addMessage(_ m: Message) {
        messages.insert(m, at: 0)
    }

    private func saveMessageLocally(_ m: Message) {
        var conv = storage.loadConversation(conversationId())
        let convData: ConversationData
        if var c = conv {
            c.messages.append(storage.messageToJson(m))
            convData = c
        } else {
            convData = ConversationData(
                id: conversationId(),
                messages: [storage.messageToJson(m)],
                createdAt: JsonStorage.dateFormatter.string(from: Date()),
                escalated: false,
                unreadCount: 0
            )
        }
        storage.saveConversation(convData)
    }

    func refreshFromServer() {
        isConnecting = true
        MessageServerHolder.shared.requestSync(since: "1970-01-01")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isConnecting = false
        }
    }

    func deleteMessage(_ message: Message) {
        if storage.removeMessage(conversationId: conversationId(), messageId: message.id) {
            if message.contentType == .image || message.contentType == .audio {
                mediaStorage.deleteMediaFile(message.content)
            }
            messages.removeAll { $0.id == message.id }
        }
    }

    func showToast(_ msg: String) {
        toastMessage = msg
    }

    func cleanup() {
        GlobalMessageManager.shared.setCurrentChat(nil)
        audioController.stop()
    }
}
