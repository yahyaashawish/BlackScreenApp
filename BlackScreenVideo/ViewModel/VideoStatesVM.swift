//
//  FontViewModel.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//

import SwiftUI
import CoreData
@MainActor
class VideoStatesVM: ObservableObject {
    
    @Published var likedVideos : [LikedVideo] = []
    var currentTask : URLSessionDataTask? = nil
    let coreDataHelper = CoreDataHelper.shared
    let errorHandler = ErrorHandler.shared

    
    init(){
        fetchLikedVideos()
    }
    
    func fetchLikedVideos(){
        let fetchRequest: NSFetchRequest<LikedVideo> = LikedVideo.fetchRequest()
        do {
            likedVideos = try coreDataHelper.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            likedVideos = []
        }
        
    }
    
    func toggleVideoLike(videoId : Int , completion : @escaping (Bool) -> Void){
        errorHandler.resetError()
        if let userId = UserIdentifier.shared.getIdentifier(){
            
            
            currentTask = LikeVideoRequest.shared.toggleVideoLike(videoId: videoId,userId: userId) { result in
                switch result{
                case .success(_):
                    if self.checkIfLiked(videoId: videoId){
                        DispatchQueue.main.async {
                            do {
                                try self.removeLikedVideo(videoId : videoId)
                                completion(true)

                            }catch{
                                completion(false)
                                self.errorHandler.presentError(error: .cannotRemoveLikeFromVideo)
                            }
                            
                        }
                    }else{
                        DispatchQueue.main.async {
                            do {
                                try self.addLikedVideo(videoId: videoId)
                                completion(true)
                            }catch{
                                self.errorHandler.presentError(error: .cannotAddLikeToVideo)
                                completion(false)
                            }
                            
                        }
                    }
                    
                    
                case .failure(_):
                    DispatchQueue.main.async {
                        if self.checkIfLiked(videoId: videoId){
                            self.errorHandler.presentError(error: .cannotRemoveLikeFromVideo)
                        }else{
                            self.errorHandler.presentError(error: .cannotAddLikeToVideo)

                        }
                    }
                    completion(false)

                }
            }
        }else{
            if self.checkIfLiked(videoId: videoId){
                self.errorHandler.presentError(error: .cannotRemoveLikeFromVideo)
            }else{
                self.errorHandler.presentError(error: .cannotAddLikeToVideo)
            }
        }
        
        
    }
    
    func checkIfLiked(videoId : Int) -> Bool {
        let stringId = String(videoId)
        return likedVideos.contains(where: { $0.video_id == stringId })
    }
    
    func removeLikedVideo(videoId : Int) throws {
        let stringId = String(videoId)
        if let index = likedVideos.firstIndex(where: { $0.video_id == stringId }){
            let likedVideo = likedVideos[index]
            coreDataHelper.persistentContainer.viewContext.delete(likedVideo)
            
                try coreDataHelper.persistentContainer.viewContext.save()
                likedVideos.remove(at: index)
            
        }
    }
    func addLikedVideo(videoId : Int) throws {
        let stringId = String(videoId)
        let newLikedVideo = LikedVideo(context: self.coreDataHelper.persistentContainer.viewContext)
        newLikedVideo.video_id = stringId
        try self.coreDataHelper.persistentContainer.viewContext.save()
        self.likedVideos.append(newLikedVideo)
    }
    
}
