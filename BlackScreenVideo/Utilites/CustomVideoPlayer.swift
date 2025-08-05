
import SwiftUI
import AVKit
struct CustomVideoPlayer: UIViewControllerRepresentable {
    var player : AVPlayer
    var isFullScreen : Bool = false
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = isFullScreen ? false : true
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.allowsPictureInPicturePlayback = true
        controller.videoGravity = .resizeAspect
        // ✅ Change background color (behind video)
        controller.view.backgroundColor = .black // ← your custom color
        
        // Also try this to ensure full hierarchy respects it

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: controller.player?.currentItem,
            queue: .main
        ){ [weak controller] _ in
            controller?.player?.seek(to: .zero,completionHandler: { _ in
                controller?.player?.play()
            })
            
        }
        
//        controller.player?.play()
        
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}


}
