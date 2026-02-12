//
//  ContactListScreen.swift
//  ChatVIP
//

import SwiftUI
import Combine

struct ContactListScreen: View {
    let myPhoneNumber: String
    let onNavigateToChat: (String) -> Void
    let onNavigateToSetup: () -> Void

    @StateObject private var viewModel = ContactListViewModel()
    @State private var showNewChat = false
    @State private var newChatNumber = ""
    @State private var newChatName = ""
    @State private var conversationToDelete: (String, String)?
    @State private var serverErrorMessage: String?
    private let storage = JsonStorage()

    private func subscribeToMessages() {
        viewModel.subscribe(myPhone: myPhoneNumber)
    }

    private func conversationId(me: String, other: String) -> String {
        let sorted = [me, other].sorted()
        return "p2p_\(sorted[0])_\(sorted[1])"
    }

    private var conversations: [(String, ConversationData)] {
        _ = viewModel.refreshId
        let localConvs = storage.listConversations()
            .filter { $0.id.hasPrefix("p2p_") }
            .compactMap { conv -> (String, ConversationData)? in
                let parts = conv.id.split(separator: "_").map { String($0) }
                let other = parts.dropFirst().first { $0 != myPhoneNumber } ?? parts.dropFirst().first
                return other.map { ($0, conv) }
            }
        let fromServer = viewModel.serverConversations.map { phone in
            (phone, storage.loadConversation(conversationId(me: myPhoneNumber, other: phone)))
        }
        let fromLocal = localConvs.filter { (phone, _) in !viewModel.serverConversations.contains(phone) }
        return (fromServer.compactMap { (phone, conv) in conv.map { (phone, $0) } } + fromLocal)
            .uniqued(by: { $0.0 })
    }

    var body: some View {
        ZStack {
            ChatVIPBackground()
            VStack(spacing: 0) {
                header
                if conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            VStack {
                Spacer()
                PoweredByFooter()
            }
        }
        .onAppear { connectToServer(); subscribeToMessages() }
        .alert("Error de Conexión", isPresented: .init(
            get: { viewModel.serverErrorMessage != nil },
            set: { if !$0 { viewModel.serverErrorMessage = nil } }
        )) {
            Button("Entendido") { viewModel.serverErrorMessage = nil }
        } message: {
            Text(viewModel.serverErrorMessage ?? "Nodo servidor no activo")
        }
        .sheet(isPresented: $showNewChat) {
            newChatSheet
        }
        .alert("Eliminar conversación", isPresented: .init(
            get: { conversationToDelete != nil },
            set: { if !$0 { conversationToDelete = nil } }
        )) {
            Button("Cancelar", role: .cancel) { conversationToDelete = nil }
            Button("Eliminar", role: .destructive) {
                if let (_, convId) = conversationToDelete {
                    storage.deleteConversation(convId)
                    viewModel.triggerRefresh()
                    conversationToDelete = nil
                }
            }
        } message: {
            if let (phone, _) = conversationToDelete {
                Text("¿Desea eliminar la conversación con \(storage.getContactName(phone) ?? phone)?")
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onNavigateToSetup) {
                Image(systemName: "gearshape.fill")
            }
            Spacer()
            VStack {
                Text("Chats")
                Text(myPhoneNumber)
                    .font(.caption)
                if !viewModel.connectionStatus.isEmpty {
                    Text(viewModel.connectionStatus)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No hay conversaciones")
            Button("Iniciar chat con un número") { showNewChat = true }
            Text("Conecta al servidor para ver tus conversaciones")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var conversationList: some View {
        List {
            ForEach(conversations, id: \.0) { phone, conv in
                let displayName = storage.getContactName(phone) ?? phone
                Button {
                    onNavigateToChat(phone)
                } label: {
                    HStack {
                        Text(String(displayName.prefix(2)).uppercased())
                            .padding(12)
                            .background(Color.accentColor.opacity(0.2))
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(displayName)
                                .fontWeight(conv.unreadCount > 0 ? .bold : .regular)
                            if storage.getContactName(phone) != nil {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let last = conv.messages.last {
                                Text(String(last.content.prefix(50)) + (last.content.count > 50 ? "..." : ""))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                .contextMenu {
                    Button("Eliminar", role: .destructive) {
                        conversationToDelete = (phone, conversationId(me: myPhoneNumber, other: phone))
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            Button {
                showNewChat = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
            }
            .padding()
        }
    }

    private var newChatSheet: some View {
        NavigationView {
            Form {
                TextField("Nombre", text: $newChatName)
                TextField("Número del contacto", text: $newChatNumber)
                    .keyboardType(.phonePad)
            }
            .navigationTitle("Nuevo chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showNewChat = false
                        newChatName = ""
                        newChatNumber = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chat") {
                        let num = newChatNumber.trimmingCharacters(in: .whitespaces)
                        if !num.isEmpty {
                            let phone = num.first?.isNumber == true ? "+\(num)" : num
                            if !newChatName.isEmpty {
                                storage.saveContactName(phone, newChatName)
                            }
                            showNewChat = false
                            newChatName = ""
                            newChatNumber = ""
                            viewModel.triggerRefresh()
                            onNavigateToChat(phone)
                        }
                    }
                }
            }
        }
    }

    private func connectToServer() {
        let config = storage.loadP2PConfig()
        guard let config = config else { return }
        if MessageServerHolder.shared.isConnected() {
            MessageServerHolder.shared.requestConversations()
            return
        }
        MessageServerHolder.shared.connect(serverUrl: config.signalingServerUrl, myPhone: config.phoneNumber)
        viewModel.connectToServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            MessageServerHolder.shared.requestConversations()
        }
    }
}

extension Array {
    func uniqued<Key: Hashable>(by keyPath: (Element) -> Key) -> [Element] {
        var seen = Set<Key>()
        return filter { seen.insert(keyPath($0)).inserted }
    }
}

private class ContactListViewModel: ObservableObject {
    @Published var serverConversations: [String] = []
    @Published var connectionStatus = ""
    @Published var refreshId = 0
    private let storage = JsonStorage()
    private var cancellables = Set<AnyCancellable>()

    func connectToServer() {
        guard let config = storage.loadP2PConfig() else { return }
        if MessageServerHolder.shared.isConnected() {
            MessageServerHolder.shared.requestConversations()
            return
        }
        MessageServerHolder.shared.connect(serverUrl: config.signalingServerUrl, myPhone: config.phoneNumber)
        MessageServerHolder.shared.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.connectionStatus = $0 }
            .store(in: &cancellables)
        MessageServerHolder.shared.conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.serverConversations = $0 }
            .store(in: &cancellables)
        MessageServerHolder.shared.errorFlow
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            MessageServerHolder.shared.requestConversations()
        }
    }

    func subscribe(myPhone: String) {
        GlobalMessageManager.shared.messageReceivedFlow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.triggerRefresh() }
            .store(in: &cancellables)
    }

    func triggerRefresh() { refreshId += 1 }
}
