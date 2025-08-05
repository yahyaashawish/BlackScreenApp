//
//  PlayerLoadingObserver.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 01/08/2025.
//


import AVKit
import Combine

class AVPlayerObserver: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    
    private var player: AVPlayer? = nil
    private var timeObserver: Any?
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    private var cancellables = Set<AnyCancellable>()
    
    func observe(player: AVPlayer) {
        guard let item = player.currentItem else {
            isLoading = true
            return
        }
        self.player = player
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        currentTime = 0
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            
            if let dur = player.currentItem?.duration.seconds, dur.isFinite {
                self.duration = dur
            }
        }

        // Observe status
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isLoading = (status != .readyToPlay)
            }
            .store(in: &cancellables)

        // Optional: Observe buffer state for smoother UX
        item.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLikely in
                if item.status == .readyToPlay {
                    self?.isLoading = !isLikely
                }
            }
            .store(in: &cancellables)
    }
    
    func clear() {
        cancellables.removeAll()
    }
    deinit {
        if let timeObserver = timeObserver , let player{
            player.removeTimeObserver(timeObserver)
        }
    }
}
