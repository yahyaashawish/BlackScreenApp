//
//  AppLibraryVM.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 02/08/2025.
//




import SwiftUI
import CoreData

class AppLibraryVM: ObservableObject {
    let coreDataHelper = CoreDataHelper.shared
    let viewContext = CoreDataHelper.shared.persistentContainer.viewContext
    @Published var saved_videos : [Video] = []
    @Published var alert : ExtractedVideoAlert = .none
    var alertMessage = ""
    @Published var presentAlert : Bool = false
    let videoFileManager = VideoFileManager.shared
    
    init(){
        fetchVideos()
    }
    
    func fetchVideos() {
        saved_videos.removeAll()
        let fetchRequest: NSFetchRequest<Video> = Video.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Video.created_at, ascending: false)]
        do {
            let results = try viewContext.fetch(fetchRequest)
            for video in results {
                saved_videos.append(video)
            }
        } catch {
            alert = .videosFetchingError
            presentAlert = true
        }
    }
    
    
    func deleteVideo(_ video: Video) {
        do {
            try videoFileManager.deleteVideo(key: video.name ?? "")
            viewContext.delete(video)
            coreDataHelper.saveContext()
            fetchVideos()
        }catch{
            alert = .videoDeletingError
            presentAlert = true
        }
        
    }
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy - h:mm" // Format: 10/2/2023 - 11:30
        return dateFormatter.string(from: date)
    }
    
    func generateBlackScreenVideos(startID : UUID)-> [BlackScreenVideo] {
        var blackVideos : [BlackScreenVideo] = []
        let firstVideo : Video? = saved_videos.first(where: {$0.id == startID})
        if let firstVideo = firstVideo {
            let firstBlackVideo = generateBlackScreenVideo(video : firstVideo, id : 0)
            if let firstBlackVideo {
                blackVideos.append(firstBlackVideo)
            }
            var counter : Int = 1
            for video in saved_videos {
                if video.id != startID {
                    if let blackVideo = generateBlackScreenVideo(video : video, id : counter) {
                        blackVideos.append(blackVideo)
                    }
                    counter += 1
                }
            }
        }
        
        
        return blackVideos
    }
    
    func generateBlackScreenVideo(video : Video, id : Int)-> BlackScreenVideo? {
        if let thumb_url = video.thumb_image_url , let video_url = video.url , let title = video.title {
            let blackVideo = BlackScreenVideo(id: id, thumbnail_url: thumb_url, video_url: video_url, name: title, category_id: 0, category_name: "", user_id: 0, username: "", likes_count: 0, views_count: 0, is_liked: 0)
            
            return blackVideo
        }
        return nil
    }
}
