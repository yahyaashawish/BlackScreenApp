//
//  GalleryAudioPicker.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 20/05/2025.
//


import SwiftUI
import UniformTypeIdentifiers

struct FileVideoPicker: UIViewControllerRepresentable {
    var onPicked: (LocalVideo) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPicked: (LocalVideo) -> Void
        
        init(onPicked: @escaping (LocalVideo) -> Void) {
            self.onPicked = onPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            let localVideo = LocalVideo(
                video_url: url,
                name: url.lastPathComponent
            )
            
            onPicked(localVideo)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}
