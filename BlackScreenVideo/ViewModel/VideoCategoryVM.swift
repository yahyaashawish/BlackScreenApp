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
    @Published var selectedCategory : VideoCategory? = nil {
        didSet {
            self.selectedCategoryVideos.removeAll()
        }
    }
    @Published var isFetchingCategories : Bool = false
    var currentCategoryPage : Int = 0
    var hasMoreCategories : Bool = true
    
    var currentCategoryVideosPage : Int = 0
    var hasMoreCategoryVideos : Bool = true
    
    @Published var isFetchingVideos : Bool = false
    var currentTask : URLSessionDataTask? = nil
    let errorHandler = ErrorHandler.shared
    
    
    func fetchCategoriesForNextPage(reloadData: Bool = false)  {
        guard isFetchingCategories == false else { return }
        if reloadData {
            self.categories.removeAll()
            self.currentCategoryPage = 1
            self.hasMoreCategories = true
        }
        if hasMoreCategories {
            self.currentCategoryPage += 1
            isFetchingCategories = true
            errorHandler.resetError()
            currentTask = VideoCategoryRequest.shared.fetchCatgories(page: currentCategoryPage) { result in
                switch result {
                case .success(let categories):
                    DispatchQueue.main.async {
                        self.categories.append(contentsOf: categories.data)
                        self.hasMoreCategories = categories.page.TotalPages > self.currentCategoryPage
                        self.isFetchingCategories = false
                    }
                case .failure(_):
                    DispatchQueue.main.async {
                        self.errorHandler.presentError(error: .fetchVideosFailed)
                        self.isFetchingCategories = false
                    }
                }
            }
        }
        
    }
    func fetchVideosForSelectedCategory(isNewCategory: Bool = false)  {
        guard isFetchingVideos == false else { return }
        if isNewCategory{
            self.selectedCategoryVideos.removeAll()
            self.currentCategoryVideosPage = 0
            self.hasMoreCategoryVideos = true
        }
        
        if let selectedCategory{

            if self.hasMoreCategoryVideos {
                self.currentCategoryVideosPage += 1

                isFetchingVideos = true
                errorHandler.resetError()
                currentTask = VideoCategoryRequest.shared.fetchCatgoryVideos(for: selectedCategory.id,page: currentCategoryVideosPage) { result in
                    switch result {
                    case .success(let videos):
                        DispatchQueue.main.async {
                            self.selectedCategoryVideos.append(contentsOf: videos.data)
                            self.hasMoreCategoryVideos = videos.page.TotalPages > self.currentCategoryVideosPage
                            self.isFetchingVideos = false
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            self.errorHandler.presentError(error: .fetchVideosFailed)
                            self.isFetchingVideos = false
                        }
                    }
                }
                

            }
           
            
        }
    }
    func cancelCurrentTask()  {
        currentTask?.cancel()
    }
}
