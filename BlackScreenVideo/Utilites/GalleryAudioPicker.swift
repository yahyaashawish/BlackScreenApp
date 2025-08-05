//
//  GalleryAudioPicker.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 20/05/2025.
//


import SwiftUI
import MediaPlayer

struct GalleryAudioPicker: UIViewControllerRepresentable {
    var onPicked: (LocalSong) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}

    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var onPicked: (LocalSong) -> Void

        init(onPicked: @escaping (LocalSong) -> Void) {
            self.onPicked = onPicked
        }

        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            mediaPicker.dismiss(animated: true)

            guard let item = mediaItemCollection.items.first,
                  let url = item.assetURL else {
                return
            }

            let name = item.title ?? "Unknown Title"
            let durationSeconds = Int(item.playbackDuration)

            let song = LocalSong(name: name, duration: durationSeconds, url: url)
            onPicked(song)
        }

        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
        }
    }
}
