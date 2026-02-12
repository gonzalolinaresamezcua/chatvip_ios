//
//  RootView.swift
//  ChatVIP
//

import SwiftUI

struct RootView: View {
    @State private var path = NavigationPath()
    @State private var refreshId = 0
    private let storage = JsonStorage()

    private var hasConfig: Bool {
        storage.loadP2PConfig() != nil
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if hasConfig {
                    ContactListScreen(
                        myPhoneNumber: storage.loadP2PConfig()?.phoneNumber ?? "",
                        onNavigateToChat: { phone in
                            path.append(phone)
                        },
                        onNavigateToSetup: {
                            path.append("setup")
                        }
                    )
                } else {
                    PhoneSetupScreen {
                        refreshId += 1
                    }
                }
            }
            .id(refreshId)
            .navigationDestination(for: String.self) { value in
                if value == "setup" {
                    PhoneSetupScreen {
                        path = NavigationPath()
                        refreshId += 1
                    }
                } else {
                    P2PChatScreen(peerPhone: value) {
                        path.removeLast()
                    }
                }
            }
        }
    }
}
