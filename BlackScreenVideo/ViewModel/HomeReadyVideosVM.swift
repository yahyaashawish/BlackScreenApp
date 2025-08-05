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
    @Published var isThereAnError : Bool = false
    var currentTask : URLSessionDataTask? = nil
    
    
    func fetchHomeVideos()  {
        isFetchingVideos = true
        isThereAnError = false
        currentTask = HomeReadyVideoRequest.shared.fetchVideos { result in
            switch result {
            case .success(let videoResponse):
                DispatchQueue.main.async {
                    self.videos = videoResponse.data
                    self.isFetchingVideos = false
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self.isThereAnError = true
                    self.isFetchingVideos = false
                }
            }
        }
    }
    
    
    deinit {
        currentTask?.cancel()
    }
}
