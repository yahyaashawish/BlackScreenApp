//
//  FontViewModel.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//

import SwiftUI
import CoreData
@MainActor
class HomeReadyVideosVM: ObservableObject {
    
    @Published var videos : [BlackScreenVideo] = []
    @Published var isFetchingVideos : Bool = false
//    @Published var isThereAnError : Bool = false
    var currentTask : URLSessionDataTask? = nil
    let errorHandler = ErrorHandler.shared
    
    func fetchHomeVideos()  {
        isFetchingVideos = true
        errorHandler.resetError()
        currentTask = HomeReadyVideoRequest.shared.fetchVideos { result in
            switch result {
            case .success(let videoResponse):
                DispatchQueue.main.async {
                    withAnimation {
                        self.videos = videoResponse.data
                        self.isFetchingVideos = false
                    }
                }
            case .failure(_):
                DispatchQueue.main.async {
                        self.errorHandler.presentError(error: .fetchVideosFailed,action: self.fetchHomeVideos)
                        self.isFetchingVideos = false
                    
                   
                }
            }
        }
    }
    
    
    deinit {
        currentTask?.cancel()
        print("data fetcher deinit")
    }
}
