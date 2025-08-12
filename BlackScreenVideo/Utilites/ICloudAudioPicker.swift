import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct ICloudAudioPicker: UIViewControllerRepresentable {
    var onPicked: (LocalSong) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio], asCopy: true)
        picker.delegate = context.coordinator
        picker.directoryURL = .homeDirectory// Ensures it starts at the Browse screen
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPicked: (LocalSong) -> Void
        
        init(onPicked: @escaping (LocalSong) -> Void) {
            self.onPicked = onPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            if url.startAccessingSecurityScopedResource() {
                let asset = AVURLAsset(url: url)
                
                Task {
                    do {
                        let duration = try await asset.load(.duration)
                        let durationSeconds = Int(CMTimeGetSeconds(duration))
                        let name = url.lastPathComponent
                        
                        let song = LocalSong(name: name, duration: durationSeconds, url: url)
                        DispatchQueue.main.async {
                            self.onPicked(song)
                        }
                    } catch {
                        print("Failed to load duration: \(error)")
                    }
                    
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
}


