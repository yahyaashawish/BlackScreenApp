//
//  VideoFileManager 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 12/11/2025.
//


import Foundation

final class ChhromaVideoFileManager {
    static let shared = ChhromaVideoFileManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Directory
    
    private var videosDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DownloadedChromaVideos")
    }
    
    // MARK: - File Operations
    
    func moveDownloadedVideo(tempURL: URL, videoID: Int) throws {
        
        try fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
        let destinationURL = localFileURL(for: videoID)
        
        // Remove if file already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: tempURL, to: destinationURL)
    }
    
    func isVideoDownloaded(videoID: Int) -> Bool {
        fileManager.fileExists(atPath: localFileURL(for: videoID).path)
    }
    
    func localFileURL(for videoID: Int) -> URL {
        let stringID = "chroma-video-\(videoID)"

        return videosDirectory.appendingPathComponent("\(stringID).mp4")
    }
    
    func deleteVideo(videoID: Int) {
        let fileURL = localFileURL(for: videoID)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    func allDownloadedVideoIDs() -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(at: videosDirectory, includingPropertiesForKeys: nil) else { return [] }
        return files.map { $0.deletingPathExtension().lastPathComponent }
    }
}
