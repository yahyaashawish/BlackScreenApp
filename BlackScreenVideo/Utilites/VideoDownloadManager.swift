//
//  VideoDownloadManager.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 12/11/2025.
//


import Foundation
import Combine

final class VideoDownloadManager: ObservableObject {
    static let shared = VideoDownloadManager()
    
    @Published var downloadProgress: [Int: Double] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private var downloadTasks: [Int: URLSessionDownloadTask] = [:]
    
    private let fileManager = ChhromaVideoFileManager.shared
    

    
    // MARK: - Download
    
    func downloadVideo(id: Int, from url: URL) {
        guard downloadTasks[id] == nil else { return }
        guard !fileManager.isVideoDownloaded(videoID: id) else { return }
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self, let tempURL else { return }
            
            do {
                try self.fileManager.moveDownloadedVideo(tempURL: tempURL, videoID: id)
                
                DispatchQueue.main.async {
                    self.downloadProgress[id] = 1.0
                    self.downloadTasks[id] = nil
                }
            } catch {
                print("Error moving video: \(error)")
            }
        }
        
        // Track progress
        let observation = task.progress.publisher(for: \.fractionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.downloadProgress[id] = progress
            }
        
        observation.store(in: &cancellables)
        
        downloadTasks[id] = task
        task.resume()
    }
    
    func cancelDownload(for id: Int) {
        downloadTasks[id]?.cancel()
        downloadTasks[id] = nil
        downloadProgress[id] = nil
    }
    
    func isVideoDownloaded(id: Int) -> Bool {
        fileManager.isVideoDownloaded(videoID: id)
    }
    
    func localFileURL(for id: Int) -> URL? {
        let url = fileManager.localFileURL(for: id)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
  
}
