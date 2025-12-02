//
//  FontViewModel.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//

import SwiftUI
import CoreData

@MainActor
class ChromaVideosVM: ObservableObject {
    
    @Published var selectedVideoId : Int = 0
    @Published var selectedVideo: ChromaVideo? = nil
    @Published var videos : [ChromaVideo] = []
    @Published var isFetchingVideos : Bool = false
    @Published var playVideo: ChromaVideo? = nil
    var currentTask : URLSessionDataTask? = nil
    let errorHandler = ErrorHandler.shared
    @Published var pageNum : Int = 1
    @Published var hasMorePages : Bool = true
    
    func fetchChromaVideos()  {
        
        guard hasMorePages else { return }
        
        isFetchingVideos = true
        errorHandler.resetError()
        currentTask = ChromaVideosRequest.shared.fetchVideos(page: pageNum) { result in
            switch result {
            case .success(let videoResponse):
                DispatchQueue.main.async {
                    withAnimation {
                        self.videos.append(contentsOf: videoResponse.data)
                        self.isFetchingVideos = false
                        if videoResponse.page.TotalPages > self.pageNum {
                            self.pageNum += 1
                        }else{
                            self.hasMorePages = false
                        }
                    }
                }
            case .failure(_):
                DispatchQueue.main.async {
                        self.errorHandler.presentError(error: .fetchVideosFailed,action: self.fetchChromaVideos)
                        self.isFetchingVideos = false
                    
                   
                }
            }
        }
    }
    
    func refreshVideos()  {
        videos.removeAll()
        pageNum = 1
        hasMorePages = true
        fetchChromaVideos()
    }
    
    
    deinit {
        currentTask?.cancel()
        print("data fetcher deinit")
    }
    
    func toogleSelectVideo(_ video:ChromaVideo)  {
        if selectedVideoId == video.id {
            withAnimation {
                selectedVideoId = 0
            }
            selectedVideo = nil
        }else {
            withAnimation {
                selectedVideoId = video.id
            }
            selectedVideo = video
        }
    }
}
