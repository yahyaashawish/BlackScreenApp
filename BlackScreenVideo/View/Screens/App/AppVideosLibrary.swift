import SwiftUI
import GoogleMobileAds

struct AppVideosLibrary: View {
    @Environment(\.layoutDirection) var layoutDirection
    @StateObject private var appLibraryVM = AppLibraryVM()
    @State var showDeleteConfirmation : Bool = false
    @State var showPlayer : Bool = false
    @State var playerFirstVideo : UUID? = nil

    
    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .bottom){
                AppBackground()
                VStack{
                    VStack{
                        if appLibraryVM.saved_videos.isEmpty{
                            Spacer()
                            VStack{
                                Image("empty-library")
                                    .resizable()
                                    .frame(width: 125,height: 137)
                                Text("You did not make any videos yet")
                                    .font(.regular16)
                                    .foregroundStyle(Color("A1A1B9"))
                                Text("Make video now")
                                    .font(.regular16)
                                    .foregroundStyle(Color("A1A1B9"))
                                
                                NewVideoButton(isForLibraryView: true)
                            }
                            Spacer()

                        }else{
                            List{
                                ForEach(appLibraryVM.saved_videos, id: \.id){ video in
                                    VideoItem(video: video, appLibraryVM: appLibraryVM) {
                                        playerFirstVideo = video.id
                                        showPlayer = true
                                    }

                                    
                                }
                                
                                .listRowBackground(Color("main-background"))
                                .listRowSeparator(.hidden)
                            }
                            .background(Color("main-background"))
                            .listStyle(.plain)
                            
                        }
                        
                    }
                }
                .padding(.horizontal,10)
                .padding(.top,10)
//                .frame(width: geometry.size.width,height: geometry.size.height)
                
                GeometryReader { adGeo in
                    let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(adGeo.size.width)
                    BannerView(adSize: adSize,isCollapsed: true, isTop: false)
                }
                .frame(height: 80)
                .safeAreaPadding(.bottom)
            }
            
        }
        .titleToolbar(title: "Videos Library")
        .navigationBarBackButtonHidden(true)
        
        .alert("Are you sure you want to delete this video?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                
            }
            Button("Yes") {
                
            }
        }
        .navigationDestination(isPresented: $showPlayer) {
            if let startVideoID = playerFirstVideo {
                let videos = appLibraryVM.generateBlackScreenVideos(startID: startVideoID)
                BlackScreenVideoPlayerView(videos: videos, startVideoID: 0,showStates: false)
                    .environment(\.layoutDirection, layoutDirection)
            }
            
        }
    }


}



struct SwipeActionButton: View {
    let iconSize = CGSize(width: 48, height: 48)
    var color: Color = Color("FF385C")
    var icon : Image = Image(systemName: "trash")
    var body: some View {
        Image(
            size: iconSize,
            label: Text("Delete")
        ) { ctx in
            let path = Path(
                roundedRect: CGRect(origin: .zero, size: iconSize),
                cornerRadius: iconSize.height / 4
            )
            ctx.fill(path, with: .color(color))
            ctx.draw(
                icon,
                at: CGPoint(x: iconSize.width / 2, y: iconSize.height / 2),
                anchor: .center
            )
        }
        .fontWeight(.bold)
        .foregroundStyle(.white)
    }
}





#Preview {
    NavigationStack{
        AppVideosLibrary()
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




