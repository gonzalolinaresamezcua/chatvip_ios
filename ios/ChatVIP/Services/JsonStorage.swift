//
//  JsonStorage.swift
//  ChatVIP
//

import Foundation

final class JsonStorage {
    private let fileManager = FileManager.default
    private var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    private var filesDir: URL { documentsURL.appendingPathComponent("chatvip_data") }
    private var conversationsDir: URL { filesDir.appendingPathComponent("conversaciones") }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale.current
        return f
    }()

    init() {
        try? fileManager.createDirectory(at: filesDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: conversationsDir, withIntermediateDirectories: true)
    }

    // MARK: - P2P Config
    private var p2pConfigURL: URL { filesDir.appendingPathComponent("p2p_config.json") }

    func loadP2PConfig() -> P2PConfig? {
        guard let data = try? Data(contentsOf: p2pConfigURL) else { return nil }
        return try? decoder.decode(P2PConfig.self, from: data)
    }

    func saveP2PConfig(_ config: P2PConfig) {
        if let data = try? encoder.encode(config) {
            try? data.write(to: p2pConfigURL)
        }
    }

    // MARK: - Conversations
    private func convFileURL(_ id: String) -> URL {
        conversationsDir.appendingPathComponent("\(id).dat")
    }

    func saveConversation(_ conv: ConversationData) {
        if let data = try? encoder.encode(conv),
           let encrypted = EncryptedStorage.encrypt(String(data: data, encoding: .utf8)) {
            try? encrypted.write(to: convFileURL(conv.id), atomically: true, encoding: .utf8)
        }
    }

    func loadConversation(_ id: String) -> ConversationData? {
        let url = convFileURL(id)
        guard let encrypted = try? String(contentsOf: url),
              let decrypted = EncryptedStorage.decrypt(encrypted),
              let data = decrypted.data(using: .utf8) else { return nil }
        return try? decoder.decode(ConversationData.self, from: data)
    }

    func listConversations() -> [ConversationData] {
        guard let files = try? fileManager.contentsOfDirectory(at: conversationsDir, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.compactMap { url -> ConversationData? in
            guard url.pathExtension == "dat" else { return nil }
            return loadConversation(url.deletingPathExtension().lastPathComponent)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func deleteConversation(_ id: String) {
        try? fileManager.removeItem(at: convFileURL(id))
    }

    func removeMessage(conversationId: String, messageId: String) -> Bool {
        guard var conv = loadConversation(conversationId) else { return false }
        let filtered = conv.messages.filter { $0.id != messageId }
        if filtered.count == conv.messages.count { return false }
        conv.messages = filtered
        saveConversation(conv)
        return true
    }

    // MARK: - Contacts
    private var contactsURL: URL { filesDir.appendingPathComponent("contacts.json") }

    func saveContactName(phone: String, name: String) {
        var contacts = loadContacts()
        contacts[phone] = name.trimmingCharacters(in: .whitespaces)
        if let data = try? encoder.encode(contacts) {
            try? data.write(to: contactsURL)
        }
    }

    func loadContacts() -> [String: String] {
        guard let data = try? Data(contentsOf: contactsURL),
              let decoded = try? decoder.decode([String: String].self, from: data) else {
            return [:]
        }
        return decoded
    }

    func getContactName(phone: String) -> String? { loadContacts()[phone] }

    func messageToJson(_ m: Message) -> MessageJson {
        MessageJson(
            id: m.id,
            type: m.type.rawValue,
            content: m.content,
            contentType: m.contentType.rawValue,
            quickReplies: m.quickReplies
        )
    }

    func jsonToMessage(_ m: MessageJson) -> Message {
        Message(
            id: m.id,
            type: MessageType(rawValue: m.type) ?? .USER,
            content: m.content,
            contentType: ContentType(rawValue: m.contentType) ?? .text,
            quickReplies: m.quickReplies
        )
    }
}
