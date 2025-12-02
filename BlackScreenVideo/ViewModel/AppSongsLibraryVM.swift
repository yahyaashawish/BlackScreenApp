//
//  BannerAdViewModel 2.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 28/12/2024.
//


import SwiftUI
import CoreData
class AppSongsLibraryVM: ObservableObject {
    @Published var isLoadingFolders = false
    @Published var folders: [SongsFolder] = []
    @Published var selectedFolder: SongsFolder? = nil
    
    @Published var hasMorePages = true
    @Published var isMyDownloadsSelected = false
    @Published var isLoadingSongs = false
    @Published var songs: [Song] = []
    @Published var songsHasMorePages = true
    @Published var searchSongName: String = ""
    let context = CoreDataHelper.shared.persistentContainer.viewContext
    var currentSongFetchTask: URLSessionDataTask?
    let errorHandler = ErrorHandler.shared

    
    
    private var songsCurrentPage : Int = 1
    private var songsTotalPages : Int = 1
    
    private var searchCurrentPage : Int = 1
    private var searchTotalPages : Int = 1
    private var searchHaseMorePages : Bool = false
    init(){
        loadFolders()
    }
    
    
    func loadFolders() {
        guard !isLoadingFolders, hasMorePages else { return }

        errorHandler.resetError()
        isLoadingFolders = true
        MusicRequest.shared.fetchFolders() { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let folderResponse):
                    self.folders.append(contentsOf: folderResponse.data)
                    self.isLoadingFolders = false
                case .failure(_):
                    self.errorHandler.presentError(error: .fetchSongsFaild,action: self.loadFolders)
                    self.isLoadingFolders = false
                }
            }
        }
        
    }
    func loadSongs(isForNewFolder : Bool) {
        currentSongFetchTask?.cancel()

        if isForNewFolder {
            self.songs.removeAll()
            songsCurrentPage = 1
            songsTotalPages = 1
            songsHasMorePages = true
        }

        if let folderID = selectedFolder?.id {

            guard !isLoadingSongs, songsHasMorePages else { return }
            
            errorHandler.resetError()
            isLoadingSongs = true
            currentSongFetchTask = MusicRequest.shared.fetchSongs(for: folderID,page: songsCurrentPage) { result in
                DispatchQueue.main.async {
                    self.currentSongFetchTask = nil
                    switch result {
                    case .success(let songsRequest):
                        self.songsTotalPages = songsRequest.page.TotalPages
                        self.songsCurrentPage += 1
                        self.songsHasMorePages = self.songsCurrentPage <= songsRequest.page.TotalPages
                        self.songs.append(contentsOf: songsRequest.data)
                        self.isLoadingSongs = false
                    case .failure(_):
                        self.errorHandler.presentError(error: .fetchSongsFaild,action: self.loadFolders)
                        self.isLoadingSongs = false
                    }
                }
            }
        }
        
    }
    func loadDownloadedSongs() {
        currentSongFetchTask?.cancel()
        currentSongFetchTask = nil
        self.isMyDownloadsSelected = true
        self.songs.removeAll()
        let fetchRequest: NSFetchRequest<DownloadedSong> = DownloadedSong.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDownloaded == %@", NSNumber(value: true))
        if let results = try? context.fetch(fetchRequest){
            for result in results {
                let song = Song(id: Int(result.id), name: result.name ?? "", duration: Int(result.duration), thumbnail: result.thumbnail ?? "", file: result.fileUrl ?? "", folder_id: 0)                
                self.songs.append(song)
            }
        }
            
        
            
        
        
    }
    
    func loadSongsWithName(name : String,isForNewNameSearch : Bool) {
        currentSongFetchTask?.cancel()

        if isForNewNameSearch {
            self.songs.removeAll()

            searchCurrentPage = 1
            searchTotalPages = 1
            searchHaseMorePages = true
        }
            guard !isLoadingSongs, searchHaseMorePages else { return }
            
        errorHandler.resetError()
            isLoadingSongs = true
            currentSongFetchTask = MusicRequest.shared.fetchSongsWithName(with: name, page: searchCurrentPage) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let songsRequest):
                        self.searchTotalPages = songsRequest.page.TotalPages
                        self.searchCurrentPage += 1
                        self.searchHaseMorePages = self.searchCurrentPage <= songsRequest.page.TotalPages
                        self.songs.append(contentsOf: songsRequest.data)
                        self.isLoadingSongs = false
                    case .failure(_):
                        self.errorHandler.presentError(error: .fetchSongsFaild,action: self.loadFolders)
                        self.isLoadingSongs = false
                    }
                }
            }        
    }
    
}
