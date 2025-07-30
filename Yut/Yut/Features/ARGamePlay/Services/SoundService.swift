//
//  SoundService.swift
//  Yut
//
//  Created by Seungeun Park on 7/29/25.
//

import AVFoundation

class SoundService {
    private var player: AVAudioPlayer?
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("\(error)")
        }
    }

    func playCollisionSound() {
        guard let url = Bundle.main.url(forResource: "ShootAndYut", withExtension: "mp3") else {
            print("파일 없음")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("\(error)")
        }
    }
    
    func playcollectYutSound() {
        guard let url = Bundle.main.url(forResource: "CollectYut", withExtension: "mp3") else {
            print("파일 없음")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("\(error)")
        }
    }
}
