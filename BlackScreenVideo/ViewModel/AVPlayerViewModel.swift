//
//  AVPlayerViewModel.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 17/02/2025.
//


import SwiftUI
import AVFoundation
import Combine
import CoreData

class AVPlayerViewModel: ObservableObject , SongCacheDelegate {
    // MARK: - Published Properties
    @Published var isPlaying: Bool = false
    @Published var errorMessage: String? = nil
    @Published var currentlyPlayingID: Int?
    @Published var selectedSong: Int?
    @Published var downloadProgress: [Int: Double] = [:] // Store progress per song
    let coreDataHelper = CoreDataHelper.shared
    // MARK: - Private Properties
    var audioPlayer: AVPlayer?

    // MARK: - Public Methods
    init() {
        SongCacheManager.shared.delegate = self
    }
    
    func downloadSong(song : Song){
        
        let cacheManager = SongCacheManager.shared
        guard isSongCached(songID: song.id) == false else { return }
        guard let songURL = URL(string: song.file) else { return }
        
        cacheManager.downloadAndCacheSong(from: songURL, songID: song.id)
        saveSongToCoreData(song: song)

    }
    
    func saveSongToCoreData(song: Song){
        let context = coreDataHelper.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<DownloadedSong> = DownloadedSong.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", song.id)
        let downloadedSong = try? context.fetch(fetchRequest).first
        
        guard downloadedSong == nil else {
            return
        }
        
        let newDownloadedSong = DownloadedSong(context: context)
        newDownloadedSong.id = Int64(song.id)
        newDownloadedSong.name = song.name
        newDownloadedSong.duration = Int16(song.duration)
        newDownloadedSong.thumbnail = song.thumbnail
        newDownloadedSong.fileUrl = song.file
        
        coreDataHelper.saveContext()
        
    }
    
    func makeSavedSongIsDownloaded(songID: Int){
        let context = coreDataHelper.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<DownloadedSong> = DownloadedSong.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", songID)
        
        do {
            if let downloadedSong = try context.fetch(fetchRequest).first {
                downloadedSong.isDownloaded = true
                try context.save()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    /// Load audio from a URL

    func cancelDownload(songID: Int) {
        SongCacheManager.shared.cancelDownload(songID: songID)
        downloadProgress.removeValue(forKey: songID) // delete song progress

    }
    
    func startPlaying(songID : Int) {
        if let url = cachedSongURL(songID: songID) {
            stop()
            audioPlayer = AVPlayer(url: url) // Load new song
            self.currentlyPlayingID = songID
            play() // Start playing
        
        }
        
    }
    /// Play the audio
    func play() {
        audioPlayer?.play()
        isPlaying = true
    }

    /// Pause the audio
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    /// Stop the audio and reset progress
    func stop() {
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
        isPlaying = false
        currentlyPlayingID = nil
    }

    /// Seek to a specific time in the audio
    func seek(to time: Double) {
        let targetTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        audioPlayer?.seek(to: targetTime)
    }
    func cachedSongURL(songID: Int) -> URL? {
        let cacheManager = SongCacheManager.shared

        if cacheManager.isSongCached(songID: songID) {
            let cachedURL = cacheManager.getCachedFileURL(for: songID)
            return cachedURL
        }
            return nil
        
    }
    func isSongCached(songID: Int) -> Bool {
        return SongCacheManager.shared.isSongCached(songID: songID)
    }
    
    func isSongSelected(songID: Int) -> Bool {
        return selectedSong == songID
    }
    func isSongDownloading(songID: Int) -> Bool {
        
        if downloadProgress[songID] != nil {
            return true
        }
        return false
    }
    
    // **Delegate Methods**
    func didUpdateDownloadProgress(for songID: Int, progress: Double) {
        DispatchQueue.main.async {
            self.downloadProgress[songID] = progress
        }
    }
    
    func didFinishDownloading(for songID: Int, fileURL: URL?) {
        DispatchQueue.main.async {
            self.downloadProgress[songID] = nil
                self.makeSavedSongIsDownloaded(songID: songID)
        }
    }


}
