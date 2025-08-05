

import SwiftUI
import MediaPlayer

struct MusicPicker: UIViewControllerRepresentable {
    @Binding var selectedSong: MPMediaItem? // The selected song

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false // Allow only one song to be selected
        picker.delegate = context.coordinator // Set the delegate
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var parent: MusicPicker

        init(_ parent: MusicPicker) {
            self.parent = parent
        }

        // Handle song selection
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            if let song = mediaItemCollection.items.first {
                parent.selectedSong = song
            }
            mediaPicker.dismiss(animated: true)
        }

        // Handle cancellation
        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
        }
    }
}
