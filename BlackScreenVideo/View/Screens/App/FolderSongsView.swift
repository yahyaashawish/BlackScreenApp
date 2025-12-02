
import SwiftUI
struct FolderSongsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.layoutDirection) var layoutDirection
    @StateObject var audioPlayerVM : AVPlayerViewModel = AVPlayerViewModel()
    @ObservedObject var songsVM : AppSongsLibraryVM
    let onSelectSong: (LocalSong) -> Void

    
    var body: some View {
        ZStack{
                ScrollView{
                    LazyVStack{
                        ForEach(songsVM.songs, id: \.id){ song in
                            SongRowView(song: song,audioPlayerVM: audioPlayerVM)
                                .onTapGesture {
                                    
                                    if let url = audioPlayerVM.cachedSongURL(songID: song.id){

                                        let selectedSong = LocalSong(name: song.name, duration: song.duration, url: url)
                                        
                                        onSelectSong(selectedSong)
                                    }
                                    
                                }
                                .onAppear{
                                    if song.id == songsVM.songs.last?.id {
                                        
                                        if songsVM.selectedFolder == nil && !songsVM.searchSongName.isEmpty{
                                            songsVM.loadSongsWithName(name: songsVM.searchSongName,isForNewNameSearch: false)
                                        }else{
                                            songsVM.loadSongs(isForNewFolder: false)
                                        }
                                    }
                                    
                                }
                        }
                    }
                }
                if songsVM.isLoadingSongs {
                    Spinner()
                }
            
                
            if songsVM.songs.isEmpty && !songsVM.isLoadingSongs{
                Text("No songs Available")
                    .font(Font.medium14)
                    .foregroundStyle(Color("9191A8"))
            }

        }
        .onAppear(){
            if songsVM.selectedFolder == nil && !songsVM.searchSongName.isEmpty{
                songsVM.loadSongsWithName(name: songsVM.searchSongName,isForNewNameSearch: false)
            }else{
                songsVM.loadSongs(isForNewFolder: false)
            }
        }
        .onDisappear(){
            audioPlayerVM.stop()
        }
        
    }
}


#Preview {
    FolderSongsView(songsVM : AppSongsLibraryVM()){ song in
        
    }
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .leftToRight )
    
}
