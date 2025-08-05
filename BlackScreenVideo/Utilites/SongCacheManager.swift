//
//  SongCacheDelegate.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 18/02/2025.
//


import Foundation
import AVFoundation

protocol SongCacheDelegate: AnyObject {
    func didUpdateDownloadProgress(for songID: Int, progress: Double)
    func didFinishDownloading(for songID: Int, fileURL: URL?)
}


class SongCacheManager: NSObject, URLSessionDownloadDelegate {
    static let shared = SongCacheManager()
    
    weak var delegate: SongCacheDelegate?

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var downloadTasks: [Int: URLSessionDownloadTask] = [:]
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    private override init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    func getCachedFileURL(for songID: Int) -> URL {
        return cacheDirectory.appendingPathComponent("\(songID).mp3")
    }
    
    func isSongCached(songID: Int) -> Bool {
        return fileManager.fileExists(atPath: getCachedFileURL(for: songID).path)
    }
    
    func downloadAndCacheSong(from url: URL, songID: Int) {
        if isSongCached(songID: songID) {
            delegate?.didFinishDownloading(for: songID, fileURL: getCachedFileURL(for: songID))
            return
        }
        
        let task = urlSession.downloadTask(with: url)
        downloadTasks[songID] = task
        task.resume()
    }
    func cancelDownload(songID: Int) {
        if let task = downloadTasks[songID] {
            task.cancel()

            downloadTasks.removeValue(forKey: songID)
            
            
        }
    }
    
    // **URLSessionDownloadDelegate Methods**
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let songID = downloadTasks.first(where: { $0.value == downloadTask })?.key else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        delegate?.didUpdateDownloadProgress(for: songID, progress: progress)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let songID = downloadTasks.first(where: { $0.value == downloadTask })?.key else { return }
        
        let destinationURL = getCachedFileURL(for: songID)
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            delegate?.didFinishDownloading(for: songID, fileURL: destinationURL)
        } catch {
            print("Failed to move file: \(error)")
            delegate?.didFinishDownloading(for: songID, fileURL: nil)
        }
        
        downloadTasks.removeValue(forKey: songID)
    }
}
