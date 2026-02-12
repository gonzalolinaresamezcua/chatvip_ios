//
//  GlobalMessageManager.swift
//  ChatVIP
//

import Foundation
import Combine

final class GlobalMessageManager {
    static let shared = GlobalMessageManager()

    let messageReceivedFlow = PassthroughSubject<(String, Message), Never>()
    private var currentChatId: String?
    private let storage = JsonStorage()
    private let mediaStorage = MediaStorage()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        startListening()
    }

    func setCurrentChat(_ chatId: String?) {
        currentChatId = chatId
        if let id = chatId { markAsRead(id) }
    }

    private func markAsRead(_ chatId: String) {
        if var conv = storage.loadConversation(chatId), conv.unreadCount > 0 {
            conv.unreadCount = 0
            storage.saveConversation(conv)
        }
    }

    private func startListening() {
        MessageServerHolder.shared.incomingMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                guard let self = self else { return }
                let config = self.storage.loadP2PConfig()
                guard let myPhone = config?.phoneNumber else { return }
                let peerPhone = msg.from == myPhone ? msg.to : msg.from
                let sorted = [myPhone, peerPhone].sorted()
                let convId = "p2p_\(sorted[0])_\(sorted[1])"
                let isCurrentChat = convId == self.currentChatId
                let unreadIncrement = isCurrentChat ? 0 : 1
                let type: MessageType = msg.from == myPhone ? .USER : .AI
                let contentTypeStr = msg.contentType.lowercased()

                let newMsg: Message?
                switch contentTypeStr {
                case "image":
                    if let data = Data(base64Encoded: msg.content) {
                        let path = self.mediaStorage.saveImage(data)
                        newMsg = Message(id: msg.id, type: type, content: path, contentType: .image)
                    } else { newMsg = nil }
                case "audio":
                    if let data = Data(base64Encoded: msg.content) {
                        let path = self.mediaStorage.saveAudio(data)
                        newMsg = Message(id: msg.id, type: type, content: path, contentType: .audio)
                    } else { newMsg = nil }
                default:
                    newMsg = Message(id: msg.id, type: type, content: msg.content, contentType: .text)
                }

                if let m = newMsg {
                    var conv = self.storage.loadConversation(convId)
                    let convData: ConversationData
                    if var c = conv {
                        c.messages.append(self.storage.messageToJson(m))
                        c.unreadCount += unreadIncrement
                        convData = c
                    } else {
                        convData = ConversationData(
                            id: convId,
                            messages: [self.storage.messageToJson(m)],
                            createdAt: JsonStorage.dateFormatter.string(from: Date()),
                            escalated: false,
                            unreadCount: unreadIncrement
                        )
                    }
                    self.storage.saveConversation(convData)
                    self.messageReceivedFlow.send((convId, m))
                }
            }
            .store(in: &cancellables)
    }
}
