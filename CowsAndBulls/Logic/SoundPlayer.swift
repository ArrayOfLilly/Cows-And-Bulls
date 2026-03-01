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
    private var backgroundPlayer: AVAudioPlayer?
    private var backgroundTrackKey: String?

    static let availableBackgroundTracks: [BackgroundTrack] = [
        .init(id: "Mushroom Background Music", displayName: "Mushroom"),
        .init(id: "Candyworld Background Music", displayName: "Candyworld"),
        .init(id: "Desert background music", displayName: "Desert")
    ]

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

        if let data = loadAudioData(for: key) {
            playFromData(data, key: key, volume: clampedVolume)
        }
    }

    func updateBackgroundMusic(enabled: Bool, trackID: String, volume: Double) {
        guard enabled, trackID.isEmpty == false else {
            stopBackgroundMusic()
            return
        }

        let clampedVolume = Float(min(max(volume, 0), 1))

        if let backgroundPlayer, backgroundTrackKey == trackID {
            backgroundPlayer.volume = clampedVolume
            if backgroundPlayer.isPlaying == false {
                backgroundPlayer.play()
            }
            return
        }

        guard let data = loadAudioData(for: trackID) else {
            stopBackgroundMusic()
            return
        }

        do {
            let player = try AVAudioPlayer(data: data)
            player.numberOfLoops = -1
            player.volume = clampedVolume
            player.prepareToPlay()
            backgroundPlayer = player
            backgroundTrackKey = trackID
            player.play()
        } catch {
            stopBackgroundMusic()
        }
    }

    func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer = nil
        backgroundTrackKey = nil
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

    private func loadAudioData(for resource: String) -> Data? {
        if let dataAsset = NSDataAsset(name: resource) {
            return dataAsset.data
        }

        let extensions = ["wav", "mp3", "m4a", "aif", "aiff"]
        for fileExtension in extensions {
            if let fileURL = Bundle.main.url(forResource: resource, withExtension: fileExtension),
               let data = try? Data(contentsOf: fileURL) {
                return data
            }
        }

        return nil
    }
}

struct BackgroundTrack: Identifiable, Hashable {
    let id: String
    let displayName: String
}
