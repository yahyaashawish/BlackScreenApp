

import SwiftUI
import AVKit

struct ExportedVideoPlayerView: View {
    @Environment(\.dismiss) var dismiss
    let videoURL : URL
    let videoSize : CGSize
    @State var player: AVPlayer = AVPlayer()
    @State var isPlaying: Bool = false
    var body: some View {
       
            ZStack{
                AppBackground()
                
                    VStack{
                        HStack{
                            AppBackButton()
                            Text("Video Player")
                                .font(Font.medium24)
                                .foregroundStyle(Color("C3C3D8"))
                            Spacer()
                            
                        }
                        .padding(.horizontal,10)
                        Spacer()
                        let maxHeight: CGFloat = 650
                        let scaledHeight = max(350, min(maxHeight, videoSize.height / 1920 * maxHeight))
                        CustomVideoPlayer(player: player)
                       

                            .background(.gray)
                            .frame(height: scaledHeight)

                        
                        Spacer()
                        
                        
                        
                        
                    }
                }
                
            
            .navigationBarBackButtonHidden(true)
            .onAppear{
                
                player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                
            }
        
        
        .environment(\.layoutDirection,  LanguageSetting.shared.isRightToLeft ? .rightToLeft : .leftToRight)

    }
    
  
   
}


#Preview {
    NavigationStack{
       
        let url = Bundle.main.url(forResource: "sample", withExtension: "mp4")
        ExportedVideoPlayerView(videoURL: url!,videoSize: CGSize(width: 1920 , height: 1080))
    }
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
    
}




