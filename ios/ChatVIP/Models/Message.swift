//
//  Message.swift
//  ChatVIP
//

import Foundation

enum MessageType: String, Codable {
    case USER
    case AI
    case SYSTEM
}

enum ContentType: String, Codable {
    case text
    case image
    case audio
}

struct Message: Identifiable {
    let id: String
    let type: MessageType
    let content: String
    let contentType: ContentType
    let quickReplies: [String]?

    init(id: String, type: MessageType, content: String, contentType: ContentType = .text, quickReplies: [String]? = nil) {
        self.id = id
        self.type = type
        self.content = content
        self.contentType = contentType
        self.quickReplies = quickReplies
    }
}

struct MessageJson: Codable {
    let id: String
    let type: String
    let content: String
    let contentType: String
    let quickReplies: [String]?
}

struct ConversationData: Codable {
    let id: String
    var messages: [MessageJson]
    let createdAt: String
    var escalated: Bool
    var unreadCount: Int
}
