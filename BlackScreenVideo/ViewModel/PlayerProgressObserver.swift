//
//  PlayerObserver.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 02/08/2025.
//

import SwiftUI
import AVFoundation

class PlayerProgressObserver: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1

    private var player: AVPlayer
    private var timeObserver: Any?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    init(player: AVPlayer) {
        self.player = player
    }
    
    func loadNewPlayerItem(){
        print("loaded new player item")
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        currentTime = 0
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            print("loaded new time \(time.seconds)")
            print("player item \(player.currentItem)")
            if let dur = player.currentItem?.duration.seconds, dur.isFinite {
                print("loaded new duration \(dur)")
                self.duration = dur
            }
        }
    }

    deinit {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
}
