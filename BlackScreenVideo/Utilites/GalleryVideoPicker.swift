//
//  VideoPicker.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 02/12/2025.
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct GalleryVideoPicker: UIViewControllerRepresentable {
    var onPicked: (LocalVideo) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onPicked: (LocalVideo) -> Void
        
        init(onPicked: @escaping (LocalVideo) -> Void) {
            self.onPicked = onPicked
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            let itemProvider = result.itemProvider
            
            guard itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }
            
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard let url, error == nil else { return }
                
                // Copy to temporary location since the provided URL is temporary
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = url.lastPathComponent
                let destinationURL = tempDirectory.appendingPathComponent(UUID().uuidString + "_" + fileName)
                
                do {
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    
                    let localVideo = LocalVideo(
                        video_url: destinationURL,
                        name: fileName
                    )
                    
                    DispatchQueue.main.async {
                        self.onPicked(localVideo)
                    }
                } catch {
                    print("Failed to copy video: \(error)")
                }
            }
        }
    }
}
