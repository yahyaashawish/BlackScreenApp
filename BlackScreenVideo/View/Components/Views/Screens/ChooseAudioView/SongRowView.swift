//
//  SongRow.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 07/02/2025.
//

import SwiftUI
import AVFoundation
struct SongRowView: View {
    
    let song: Song
    @ObservedObject var audioPlayerVM : AVPlayerViewModel
    

    @State var isSongPlaying : Bool = false
    private var isSongDownloading: Bool {
        audioPlayerVM.downloadProgress[song.id] != nil
    }
    var isSongDownloaded : Bool {
        return SongCacheManager.shared.isSongCached(songID: song.id)
    }
    var body: some View {
        ZStack{
                Color.clear
                    .contentShape(Rectangle())
            VStack(alignment: .leading,spacing: 20) {
                HStack (spacing:15){
                    
                        
                        Button(action: {
                            if isSongDownloaded {
                                togglePlay()
                            }else{
                                if isSongDownloading {
                                    audioPlayerVM.cancelDownload(songID: song.id)
                                }else{
                                    audioPlayerVM.downloadSong(song: song)
                                }
                            }
                            
                            
                        }) {
                            
                           
                                ZStack{
                                    AsyncImage(url: URL(string: song.thumbnail)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.secondry.opacity(0.5)
                                    }
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Rectangle()
                                            .fill(.black.opacity(0.3))
                                    }
                                    .clipShape(.rect(cornerRadius: 15))
                                    
                                    if isSongDownloaded {
                                        Image(systemName: isSongPlaying && audioPlayerVM.currentlyPlayingID == song.id ? "pause.fill" : "play.fill")
                                            .resizable()
                                            .frame(width: 15, height: 15)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal,5)
                                        
                                    }else{
                                        if isSongDownloading {
                                            let progress = $audioPlayerVM.downloadProgress[song.id]
                                            CircleProgressBarWithCancelButton(progress:  progress)
                                                .padding(.horizontal,5)
                                            
                                        }else{
                                            Image(systemName: "arrow.down.to.line.circle.fill")
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal,5)
                                            
                                        }
                                    }
                                    
                                    
                                }
                                
                                
                            
                            
                        }
                    
                    
                    VStack(alignment:.leading){
                        Text(song.name)
                            .font(Font.regular16)
                            .foregroundStyle(Color("A1A1B9"))
                        
                        Text(formatSecondsToMinutesSeconds(song.duration))
                            .font(Font.regular10)
                            .foregroundStyle(Color("6C6C7B"))
                        
                        
                    }
                    
                    
                    Spacer()
                    if audioPlayerVM.isSongCached(songID: song.id){
                        Image("check-mark")
                    }
                    
                    
                    
                }
                Divider()
                
                
                
            }
            
            .padding(.vertical, 8)
        }
        
        
    }
    func togglePlay(){
        if isSongPlaying && audioPlayerVM.currentlyPlayingID == song.id{
            audioPlayerVM.pause()
            isSongPlaying = false
        }else{
            if audioPlayerVM.currentlyPlayingID != song.id {
                audioPlayerVM.startPlaying(songID: song.id)
                isSongPlaying = true
            }else{
                audioPlayerVM.play()
                isSongPlaying = true

            }
        }
    }
    func formatSecondsToMinutesSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    NavigationStack{
        SongRowView(song: Song(id: 2, name: "test song", duration: 333,thumbnail: "" ,file: "" ,folder_id: 3), audioPlayerVM: AVPlayerViewModel())
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}

