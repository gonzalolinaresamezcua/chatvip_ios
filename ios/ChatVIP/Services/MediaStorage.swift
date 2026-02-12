//
//  MediaStorage.swift
//  ChatVIP
//

import Foundation
import UIKit
import Photos

final class MediaStorage {
    private let fileManager = FileManager.default
    private var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    private var baseDir: URL { documentsURL.appendingPathComponent("chatvip") }
    private var imgDir: URL { baseDir.appendingPathComponent("img") }
    private var audioDir: URL { baseDir.appendingPathComponent("audio") }

    init() {
        try? fileManager.createDirectory(at: imgDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
    }

    func saveImage(_ data: Data, extension ext: String = "jpg") -> String {
        let name = "img_\(UUID().uuidString.prefix(8)).\(ext)"
        let file = imgDir.appendingPathComponent(name)
        try? data.write(to: file)
        return "chatvip/img/\(name)"
    }

    func saveAudio(_ data: Data, extension ext: String = "m4a") -> String {
        let name = "audio_\(UUID().uuidString.prefix(8)).\(ext)"
        let file = audioDir.appendingPathComponent(name)
        try? data.write(to: file)
        return "chatvip/audio/\(name)"
    }

    func resolvePath(_ relativePath: String) -> URL {
        relativePath.split(separator: "/").reduce(documentsURL) { $0.appendingPathComponent(String($1)) }
    }

    func fileExists(_ relativePath: String) -> Bool {
        fileManager.fileExists(atPath: resolvePath(relativePath).path)
    }

    func saveImageToGallery(relativePath: String) -> String? {
        let file = resolvePath(relativePath)
        guard fileManager.fileExists(atPath: file.path),
              let image = UIImage(contentsOfFile: file.path) else { return nil }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        return "Guardado en Fotos"
    }

    func saveAudioToDownloads(relativePath: String) -> String? {
        let file = resolvePath(relativePath)
        guard fileManager.fileExists(atPath: file.path) else { return nil }
        // En iOS guardamos en el directorio de documentos compartibles
        let downloads = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ChatVIP")
        try? fileManager.createDirectory(at: downloads, withIntermediateDirectories: true)
        let dest = downloads.appendingPathComponent("audio_\(Date().timeIntervalSince1970).m4a")
        try? fileManager.copyItem(at: file, to: dest)
        return "Guardado en ChatVIP"
    }

    func deleteMediaFile(_ relativePath: String) {
        try? fileManager.removeItem(at: resolvePath(relativePath))
    }
}
