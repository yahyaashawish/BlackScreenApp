import SwiftUI
import AVKit

struct BlackScreenVideoPlayerView: View {
    let videos: [BlackScreenVideo]
    let startVideoID: Int
    var showStates: Bool = true
    @State private var currentIndex = 0
    @State var player: AVPlayer = AVPlayer()
    @State var scrollPostion: Int?
    @State private var playbackWorkItem: DispatchWorkItem?
    @State private var isPlaying: Bool = false
    @StateObject var playerObserver = AVPlayerObserver()
    @StateObject var videoStatesVM = VideoStatesVM()
    


    var body: some View {
        VStack{
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        if let firstVideo = getFirstVideo(){
                            VideoPageView(video: firstVideo, player: player,playerObserver: playerObserver,isPlaying: $isPlaying,showStates: showStates,videoStatesVM: videoStatesVM)
                                .id(firstVideo.id)
                        }
                        ForEach(videos,id: \.id) { video in
                            if video.id != startVideoID{
                                VideoPageView(video: video, player: player,playerObserver: playerObserver,isPlaying: $isPlaying,showStates: showStates,videoStatesVM: videoStatesVM)
                                    .id(video.id)
                            }
                            
                            
                        }
                        
                    }
                    .scrollTargetLayout()
                    
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea()
                .scrollPosition(id :$scrollPostion)
                .onChange(of: scrollPostion) { oldValue, newValue in
                    guard newValue != oldValue else { return }
                    
                    // Cancel any pending playback tasks
                    playbackWorkItem?.cancel()
                    
                    // Pause current video immediately
                    player.pause()
                    isPlaying = false
                    player.replaceCurrentItem(with: nil)
                    
                    // Create a new work item
                    let workItem = DispatchWorkItem {
                        playVideo(with: newValue)
                    }
                    
                    // Save it so it can be cancelled later
                    playbackWorkItem = workItem
                    
                    // Schedule the task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
                    
                }
                .onAppear{
                    playVideo(with: startVideoID)
                }
                .onChange(of: playerObserver.isLoading, { oldValue, newValue in
                    if !newValue {

                        player.play()

                        isPlaying = true
                        print("playing video")

                    }
                })
                .onDisappear {
                    player.pause()
                }
                .navigationBarBackButtonHidden(true)
        }
    }
  
    func getFirstVideo() -> BlackScreenVideo? {
        if let initialIndex = videos.firstIndex(where: { $0.id == startVideoID }){
            return videos[initialIndex]
        }
        return nil
    }
    
    func playVideo(with id: Int?){
        if let id {
            if let videoIndex = videos.firstIndex(where: { $0.id == id }){
                if let url = URL(string: videos[videoIndex].video_url) {
                    let item = AVPlayerItem(url: url)
                    player.replaceCurrentItem(with: item)
                    playerObserver.observe(player: player)
                }
            }
        }
        
    }
    
   
}




struct VideoPageView: View {
    let video: BlackScreenVideo
    let player: AVPlayer

    @ObservedObject var playerObserver: AVPlayerObserver
    @Binding var isPlaying: Bool

    let showStates: Bool
    @ObservedObject var videoStatesVM: VideoStatesVM

    @State var showPlayIcon : Bool = false
    @State var showPauseIcon : Bool = false
    @State var isLiked: Bool = false
    @State var likesCount: Int = 0
    @State private var heartScale: CGFloat = 1.0

    
    var body: some View {
        ZStack(alignment: .topLeading) {
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
                    
                }
                
                Spacer()
                    
                VStack{
                    if showStates {
                        HStack{
                            VStack(spacing: 10){
                                Button {
                                    toggleVideoLike()
                                    videoStatesVM.toggleVideoLike(videoId: video.id){ status in
                                        if !status {
                                            DispatchQueue.main.async {
                                                self.toggleVideoLike()
                                            }
                                        }
                                    }
                                } label: {
                                    VStack(spacing:5){
                                        Image(systemName: isLiked ? "heart.fill" : "heart"  )
                                            .resizable()
                                            .foregroundStyle(isLiked ? .red : .white)
                                            .frame(width: 24,height: 21)
                                            .scaleEffect(heartScale)
                                            
                                        Text(String(likesCount))
                                            .font(.medium16)
                                            .foregroundStyle(.white)
                                        
                                    }
                                }
                                .onAppear {
                                    self.isLiked = videoStatesVM.checkIfLiked(videoId: video.id)
                                    self.likesCount = video.likes_count
                                }

                                if let videoURL = URL(string: video.video_url),
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
                                //                            Image("share-video")
                                
                            }
                            Spacer()
                        }
                    }
                    VStack{
                        if !isPlaying{
                            PlayerProgressBar(observer: playerObserver)
                        }
                    }
                    .frame(height: 20)
                       
                    }
                    .padding(.bottom,20)
                    
                
                
            }
            .padding(.horizontal,20)
            .padding(.vertical,40)
        }
        
        
    }
    func toggleVideoLike() {
        if isLiked {
            // Unlike animation (shrink slightly then back)
            withAnimation(.spring) {
                heartScale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring) {
                    heartScale = 1.0

                }
            }
            likesCount -= 1
            isLiked = false
            
        } else {
            // Like animation (pop bigger then back)
            withAnimation(.spring) {
                heartScale = 1.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring) {
                    heartScale = 1.0
                    
                }
            }
            likesCount += 1
            isLiked = true
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
struct PlayerProgressBar: View {
    @ObservedObject var observer: AVPlayerObserver
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.3)).frame(height: 4)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * observer.progress, height: 4)
            }
            .cornerRadius(2)
        }
        .frame(height: 4)
        .padding(.horizontal)
    }
}
//#Preview(body: {
//VideoPageView(video: .init(id: 3, thumbnail_url: "", video_url: "http://backendiosapp.com/blackscreen/public/videos/0_1751581077_2792.mp4", name: "test", category_id: 3, category_name: "test", user_id: 2, username: "test", likes_count: 55, views_count: 111, is_liked: 1), player: .init(url: URL(string: "http://backendiosapp.com/blackscreen/public/videos/0_1751581077_2792.mp4")!), isActive: true, isPlaying: .constant(true))
//})
