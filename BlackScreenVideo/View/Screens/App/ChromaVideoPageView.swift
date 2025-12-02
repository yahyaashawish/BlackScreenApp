//
//  VideoPageView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 14/11/2025.
//

import SwiftUI
import AVFoundation
struct ChromaVideoPageView: View {
    let video: ChromaVideo
    let onSelectVideo: (LocalVideo) -> Void

    let player: AVPlayer = AVPlayer()

    @StateObject var playerObserver: AVPlayerObserver = AVPlayerObserver()
    @State var isPlaying: Bool = false
    
    @State var showPlayIcon : Bool = false
    @State var showPauseIcon : Bool = false
    @State var isLiked: Bool = false
    @State var likesCount: Int = 0
    @State private var heartScale: CGFloat = 1.0

    var localVideoURL: URL? {
        VideoDownloadManager.shared.localFileURL(for: video.id)
    }
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack{
                CustomVideoPlayer(player: player, isFullScreen: true)
                    .ignoresSafeArea()
                
                if showPlayIcon {
                    Image(systemName: "play.fill")
                        .resizable()
                        .frame(width: 50,height: 50)
                        .foregroundStyle(.white)
                }
               
                
                if showPauseIcon  {
                    Image(systemName: "pause.fill")
                        .resizable()
                        .frame(width: 50,height: 60)
                        .foregroundStyle(.white)
                    
                }
                
                if playerObserver.isLoading {
                    Spinner()
                }
            }
            .containerRelativeFrame([.horizontal,.vertical])
            // Optional tap to pause/play
            Color.clear.contentShape(Rectangle()).onTapGesture {
                togglePlayback()
            }
            
            VStack{
                HStack{
                    AppBackButton()
                    Text(video.name)
                        .font(Font.medium24)
                        .foregroundStyle(Color("C3C3D8"))
                    Spacer()
                    
                    if let videoURL = localVideoURL,
                       let thumbnailURL = URL(string: video.thumbnail_url) {
                        
                        AsyncImage(url: thumbnailURL) { phase in
                            switch phase {
                            case .success(let image):
                                ShareLink(
                                    item: videoURL,
                                    preview: SharePreview(video.name, image: image)
                                ) {
                                    Image("share-video")
                                }
                                
                            default:
                                // Fallback while loading image or if it fails
                                ShareLink(item: videoURL) {
                                    Image("share-video")
                                }
                            }
                        }
                        
                        
                    }
                    
                }
                
                Spacer()
                    
                VStack{
                    VStack{
                        if !isPlaying{
                            PlayerProgressBar(observer: playerObserver)
                        }
                    }
                    .frame(height: 20)
                       
                    }
                    .padding(.bottom,80)
                    .padding(20)

                
                
            }
            .padding(.horizontal,15)
            if let selectedVideoURL = localVideoURL{
                ChooseVideoButton{
                    let localVideo = LocalVideo(video_url: selectedVideoURL, name: video.name)
                    onSelectVideo(localVideo)
                }
            }
            
        }
        .onAppear{
            if let url = localVideoURL {
                let item = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: item)
                playerObserver.observe(player: player)
                togglePlayback()
            }
        }
        
        
    }
    func togglePlayback() {
        if player.timeControlStatus == .playing {
            player.pause()
            togglePauseIcon()
            isPlaying = false
            
        } else {
            player.play()
            togglePlayIcon()
            isPlaying = true
        }
    }
    
    func togglePlayIcon(){
        withAnimation {
            self.showPlayIcon = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.showPlayIcon = false
            }
        }
    }
    func togglePauseIcon(){
        withAnimation {
            self.showPauseIcon = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.showPauseIcon = false
            }
        }
        
    }
}
