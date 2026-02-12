//
//  MessageServerClient.swift
//  ChatVIP
//

import Foundation

protocol MessageServerListener: AnyObject {
    func onConnected()
    func onDisconnected(reason: String?)
    func onRegistered()
    func onMessage(id: String, from: String, to: String, content: String, contentType: String, timestamp: String)
    func onAck(id: String, timestamp: String)
    func onSyncDone(count: Int)
    func onConversations(list: [String])
    func onError(message: String)
}

final class MessageServerClient {
    private let serverUrl: String
    private let myPhoneNumber: String
    private weak var listener: MessageServerListener?
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var isConnecting = false

    init(serverUrl: String, myPhoneNumber: String, listener: MessageServerListener) {
        self.serverUrl = serverUrl
        self.myPhoneNumber = myPhoneNumber
        self.listener = listener
    }

    func connect() {
        guard let url = URL(string: serverUrl) else {
            listener?.onError(message: "URL inválida")
            return
        }
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnecting = true
        listener?.onConnected()
        receiveMessage()
        register()
    }

    private func register() {
        let msg: [String: Any] = ["type": "register", "phoneNumber": myPhoneNumber]
        sendMessage(msg)
    }

    func sendMessage(_ to: String, content: String, contentType: String = "text") {
        let msg: [String: Any] = [
            "type": "message",
            "to": to,
            "content": content,
            "contentType": contentType
        ]
        sendMessage(msg)
    }

    func requestSync(since: String = "1970-01-01") {
        sendMessage(["type": "sync", "since": since])
    }

    func requestConversations() {
        sendMessage(["type": "conversations"])
    }

    private func sendMessage(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(str)) { [weak self] error in
            if let error = error {
                self?.listener?.onError(message: error.localizedDescription)
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                self?.listener?.onDisconnected(reason: error.localizedDescription)
            }
        }
    }

    private func handleMessage(_ jsonStr: String) {
        guard let data = jsonStr.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            listener?.onError(message: "Mensaje inválido")
            return
        }
        let type = obj["type"] as? String ?? ""
        switch type {
        case "registered":
            isConnecting = false
            listener?.onRegistered()
        case "message":
            let id = obj["id"] as? String ?? ""
            let from = obj["from"] as? String ?? ""
            let to = obj["to"] as? String ?? ""
            let content = obj["content"] as? String ?? ""
            let contentType = obj["contentType"] as? String ?? "text"
            let timestamp = obj["timestamp"] as? String ?? ""
            listener?.onMessage(id: id, from: from, to: to, content: content, contentType: contentType, timestamp: timestamp)
        case "ack":
            let id = obj["id"] as? String ?? ""
            let timestamp = obj["timestamp"] as? String ?? ""
            listener?.onAck(id: id, timestamp: timestamp)
        case "sync_done":
            let count = obj["count"] as? Int ?? 0
            listener?.onSyncDone(count: count)
        case "conversations":
            let list = obj["list"] as? [String] ?? []
            listener?.onConversations(list: list)
        case "error":
            let msg = obj["msg"] as? String ?? "Error del servidor"
            listener?.onError(message: msg)
        default:
            listener?.onError(message: "Tipo desconocido: \(type)")
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    var isConnected: Bool {
        guard let task = webSocketTask else { return false }
        var connected = false
        let sem = DispatchSemaphore(value: 0)
        task.sendPing { error in
            connected = (error == nil)
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 2)
        return connected
    }
}
