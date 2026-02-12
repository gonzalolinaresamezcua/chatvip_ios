//
//  EncryptedStorage.swift
//  ChatVIP
//

import Foundation
import CommonCrypto

enum EncryptedStorage {
    private static let keyString = "bitcoin"
    private static let algorithm = kCCAlgorithmAES

    private static var key: Data {
        keyString.data(using: .utf8)!.sha256
    }

    static func encrypt(_ plainText: String) -> String? {
        guard let data = plainText.data(using: .utf8) else { return nil }
        let iv = Data((0..<blockSize).map { _ in UInt8.random(in: 0...255) })
        let encrypted = data.aesEncrypt(key: key, iv: iv)
        guard let enc = encrypted else { return nil }
        return iv.hexString + ":" + enc.hexString
    }

    static func decrypt(_ encryptedText: String) -> String? {
        let parts = encryptedText.split(separator: ":")
        guard parts.count == 2,
              let iv = Data(hexString: String(parts[0])),
              let encrypted = Data(hexString: String(parts[1])) else { return nil }
        guard let decrypted = encrypted.aesDecrypt(key: key, iv: iv),
              let result = String(data: decrypted, encoding: .utf8) else { return nil }
        return result
    }
}

extension Data {
    var sha256: Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash) }
        return Data(hash)
    }

    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            guard let byte = UInt8(hexString[i..<j], radix: 16) else { return nil }
            data.append(byte)
            i = j
        }
        self = data
    }

    func aesEncrypt(key: Data, iv: Data) -> Data? {
        let blockSize = kCCBlockSizeAES128
        var outLength: Int = 0
        var outBytes = [UInt8](repeating: 0, count: count + blockSize)
        let status = withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        algorithm,
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, key.count,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, count,
                        &outBytes, outBytes.count,
                        &outLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { return nil }
        return Data(bytes: outBytes, count: outLength)
    }

    func aesDecrypt(key: Data, iv: Data) -> Data? {
        let blockSize = kCCBlockSizeAES128
        var outLength: Int = 0
        var outBytes = [UInt8](repeating: 0, count: count + blockSize)
        let status = withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        algorithm,
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, key.count,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, count,
                        &outBytes, outBytes.count,
                        &outLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { return nil }
        return Data(bytes: outBytes, count: outLength)
    }
}
