//
//  MessageServerHolder.swift
//  ChatVIP
//

import Foundation
import Combine

final class MessageServerHolder {
    static let shared = MessageServerHolder()

    struct IncomingMessage {
        let id: String
        let from: String
        let to: String
        let content: String
        let contentType: String
        let timestamp: String
    }

    let incomingMessages = PassthroughSubject<IncomingMessage, Never>()
    let conversations = PassthroughSubject<[String], Never>()
    let connectionStatus = CurrentValueSubject<String, Never>("")
    let errorFlow = PassthroughSubject<String, Never>()

    private var client: MessageServerClient?
    private var listenerWrapper: ListenerWrapper?

    private init() {}

    func connect(serverUrl: String, myPhone: String) {
        let normalized = myPhone.trimmingCharacters(in: .whitespaces)
        let phone = normalized.first?.isNumber == true ? "+\(normalized)" : normalized

        client?.disconnect()
        let wrapper = ListenerWrapper(holder: self)
        listenerWrapper = wrapper
        let c = MessageServerClient(serverUrl: serverUrl, myPhoneNumber: phone, listener: wrapper)
        client = c
        c.connect()
    }

    func sendMessage(to: String, content: String, contentType: String = "text") {
        client?.sendMessage(to, content: content, contentType: contentType)
    }

    func requestSync(since: String = "1970-01-01") {
        client?.requestSync(since: since)
    }

    func requestConversations() {
        client?.requestConversations()
    }

    func disconnect() {
        client?.disconnect()
        client = nil
        listenerWrapper = nil
        connectionStatus.send("")
    }

    func isConnected() -> Bool {
        client?.isConnected ?? false
    }

    private class ListenerWrapper: MessageServerListener {
        weak var holder: MessageServerHolder?
        init(holder: MessageServerHolder) { self.holder = holder }
        func onConnected() { holder?.connectionStatus.send("Conectando...") }
        func onDisconnected(reason: String?) {
            holder?.connectionStatus.send("")
            holder?.errorFlow.send("Servidor no activo o desconectado")
        }
        func onRegistered() { holder?.connectionStatus.send("En línea") }
        func onMessage(id: String, from: String, to: String, content: String, contentType: String, timestamp: String) {
            holder?.incomingMessages.send(IncomingMessage(id: id, from: from, to: to, content: content, contentType: contentType, timestamp: timestamp))
        }
        func onAck(id: String, timestamp: String) {}
        func onSyncDone(count: Int) {}
        func onConversations(list: [String]) { holder?.conversations.send(list) }
        func onError(message: String) {
            holder?.connectionStatus.send("Error")
            holder?.errorFlow.send("Error: Nodo servidor no activo")
        }
    }
}

extension Character {
    var isNumber: Bool { isWholeNumber }
}
