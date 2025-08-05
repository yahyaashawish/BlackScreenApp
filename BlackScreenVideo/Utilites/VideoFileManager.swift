
import Foundation
import SwiftUI
import AVFoundation

class VideoFileManager {
    
    static let shared = VideoFileManager()
    let folderName = "saved_videos"
    let thumbnailsFolderName = "saved_thumbnails"
    
    private init() {
        createFolderIfNeeded()
        createThumbnailsFolderIfNeeded()
    }
    
    func createFolderIfNeeded() {
        guard let url = getFolderPath() else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                print("Created folder!")
            } catch let error {
                print("Error creating folder. \(error)")
            }
        }
    }
    
    func createThumbnailsFolderIfNeeded() {
        guard let url = getThumnailFolderPath() else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                print("Created thumbnails folder!")
            } catch let error {
                print("Error creating folder. \(error)")
            }
        }
    }
    
    func getFolderPath() -> URL? {
        return FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }
    
    func getThumnailFolderPath() -> URL? {
        return FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(thumbnailsFolderName)
    }
    

    func getVideoURL(key: String) -> URL? {
        guard let folder = getFolderPath() else {
            return nil
        }
        return folder.appendingPathComponent(key + ".mp4")
    }
    
    func getThumbnailURL(key: String) -> URL? {
        guard let folder = getThumnailFolderPath() else {
            return nil
        }
        return folder.appendingPathComponent(key + ".png")
    }
    // Save Video to App Directory
    func saveVideo(key : String ,from:URL , thumb : UIImage) throws -> (videoURL : URL,thumbURL : URL)? {
        
        guard let videoURL = getVideoURL(key : key) else { return nil }

        do {
            if let thumbUrl = try saveThumbnail(for: key,thumb: thumb){
                try FileManager.default.copyItem(at: from, to: videoURL)
                return (videoURL,thumbUrl)
            }else{
                return nil
            }
        } catch {
            throw error
        }

    }
    
    func deleteVideo(key : String) throws {
        guard
            let videoUrl = getVideoURL(key: key),let thumbnailURL = getThumbnailURL(key: key),
            FileManager.default.fileExists(atPath: videoUrl.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: videoUrl.path)
            try deleteThumbnail(url: thumbnailURL)
        } catch {
            throw error
        }
    }
    // Generate Thumbnail
    func saveThumbnail(for videoKey: String,thumb : UIImage)  throws -> URL? {
       
            do {
                let thumbnail = thumb.resized(toFit: CGSize(width: 120, height: 120)) // Resize here

                if let imageData = thumbnail?.pngData() {
                    guard let thumbnailURL = getThumbnailURL(key: videoKey) else { return nil }
                    
                    try imageData.write(to: thumbnailURL)
                    return thumbnailURL
                }
            } catch {
                print("Error saving thumbnail: \(error)")
                throw error
            }
        return nil
        
        
    }
    func getThumbImage(key: String) -> UIImage? {
        guard
            let url = getThumbnailURL(key: key),
            FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteThumbnail(url: URL) throws {
        guard
            
            FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: url.path)
        } catch {
            throw error
        }
    }
    
    func getExistingVideoURL(key: String) -> URL? {
        guard
            let url = getVideoURL(key: key),
            FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return url
    }
    
    
}
