//
//  P2PConfig.swift
//  ChatVIP
//

import Foundation

struct P2PConfig: Codable {
    let phoneNumber: String
    var signalingServerUrl: String
    var userName: String?

    static let defaultServerUrl = "ws://10.0.0.1:9090"
}
