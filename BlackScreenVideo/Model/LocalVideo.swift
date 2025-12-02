//
//  LocalVideo.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 17/11/2025.
//


import Foundation
import UIKit
import AVFoundation


struct LocalVideo: Identifiable{
    let id : UUID = UUID()
    let video_url : URL
    let name : String
    
    var duration: Double? {
        let asset = AVURLAsset(url: video_url)
        let duration = CMTimeGetSeconds(asset.duration)   // <-- extract duration
        return duration
    }

    
    func getVideoThumb(
        at time: CMTime = .init(seconds: 1, preferredTimescale: 600),
        completion: @escaping (UIImage?) -> Void
    )  {
        let asset = AVURLAsset(url: video_url)
        
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            generator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
                if let cgImage = cgImage {
                    completion(UIImage(cgImage: cgImage))
                } else {
                    print("Thumbnail error:", error?.localizedDescription ?? "Unknown error")
                    completion(nil)
                }
            }
            completion(nil,)

        
        
    }

    
}


