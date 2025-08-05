//
//  FontViewModel.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//

import SwiftUI
import CoreData
@MainActor
class VideoCategoryVM: ObservableObject {
    
    @Published var categories : [VideoCategory] = []
    @Published var selectedCategoryVideos : [BlackScreenVideo] = []
    @Published var selectedCategory : VideoCategory? = nil
    @Published var isFetchingCategories : Bool = false
    @Published var isFetchingVideos : Bool = false
    @Published var isThereAnError : Bool = false
    var currentTask : URLSessionDataTask? = nil
    
    
    func fetchCategories()  {
        isFetchingCategories = true
        isThereAnError = false
        currentTask = VideoCategoryRequest.shared.fetchCatgories { result in
            switch result {
            case .success(let categories):
                DispatchQueue.main.async {
                    self.categories = categories.data
                    self.isFetchingCategories = false
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self.isThereAnError = true
                    self.isFetchingCategories = false
                }
            }
        }
    }
    func fetchVideosForSelectedCategory()  {
        if let selectedCategory {
            isFetchingVideos = true
            isThereAnError = false
            currentTask = VideoCategoryRequest.shared.fetchCatgoryVideos(for: selectedCategory.id) { result in
                switch result {
                case .success(let videos):
                    DispatchQueue.main.async {
                        self.selectedCategoryVideos = videos.data
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
    }
    func cancelCurrentTask()  {
        currentTask?.cancel()
    }
}
