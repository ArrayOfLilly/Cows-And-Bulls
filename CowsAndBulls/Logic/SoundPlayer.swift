//
//  SoundPlayer.swift
//  CowsAndBulls
//

import Foundation
import AVFoundation
import AppKit

final class SoundPlayer {
    static let shared = SoundPlayer()

    enum Effect: String {
        case submit
        case win
        case lose
    }

    private var players: [String: AVAudioPlayer] = [:]

    private init() {}

    func play(_ effect: Effect, enabled: Bool, volume: Double) {
        guard enabled else { return }
        let clampedVolume = Float(min(max(volume, 0), 1))

        let key = effect.rawValue

        if let cached = players[key] {
            cached.volume = clampedVolume
            cached.currentTime = 0
            cached.play()
            return
        }

        if let dataAsset = NSDataAsset(name: key) {
            playFromData(dataAsset.data, key: key, volume: clampedVolume)
            return
        }

        if let fileURL = Bundle.main.url(forResource: key, withExtension: "wav"),
           let data = try? Data(contentsOf: fileURL) {
            playFromData(data, key: key, volume: clampedVolume)
        }
    }

    private func playFromData(_ data: Data, key: String, volume: Float) {
        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = volume
            player.prepareToPlay()
            players[key] = player
            player.play()
        } catch {
            // Ignore playback errors to avoid impacting gameplay.
        }
    }
}
