//
//  AudioPlayerController.swift
//  ChatVIP
//

import Foundation
import AVFoundation
import Combine

final class AudioPlayerController: NSObject, ObservableObject {
    @Published var currentPlayingMessageId: String?
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentPosition = 0
    @Published var duration = 0
    @Published var sliderPosition: Float = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func playOrPause(file: URL, messageId: String) {
        if currentPlayingMessageId == messageId {
            if isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
            isPlaying.toggle()
        } else {
            stop()
            startPlayback(file: file, messageId: messageId)
        }
    }

    private func startPlayback(file: URL, messageId: String) {
        currentPlayingMessageId = messageId
        isLoading = true
        do {
            player = try AVAudioPlayer(contentsOf: file)
            player?.delegate = self
            player?.prepareToPlay()
            duration = Int(player?.duration ?? 0) * 1000
            isLoading = false
            player?.play()
            isPlaying = true
            startProgressTracker()
        } catch {
            stop()
        }
    }

    func seekTo(_ position: Float) {
        guard let p = player else { return }
        let newPos = Int(position * Float(duration))
        p.currentTime = Double(newPos) / 1000
        currentPosition = newPos
        sliderPosition = position
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        currentPlayingMessageId = nil
        isPlaying = false
        isLoading = false
        currentPosition = 0
        duration = 0
        sliderPosition = 0
    }

    private func startProgressTracker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let p = self.player, p.isPlaying else { return }
            self.currentPosition = Int(p.currentTime * 1000)
            if self.duration > 0 {
                self.sliderPosition = Float(self.currentPosition) / Float(self.duration)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func formatTime(_ millis: Int) -> String {
        let totalSeconds = millis / 1000
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

extension AudioPlayerController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentPosition = 0
        sliderPosition = 0
    }
}
