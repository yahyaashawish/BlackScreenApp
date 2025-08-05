//
//  Video.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 03/08/2025.
//


import SwiftUI
import CoreData


extension Video  {
    
    
    public func loadThumbImage(completion: @escaping (UIImage?) -> Void) {
        
        if let thumbnail = VideoFileManager.shared.getThumbImage(key:  self.name ?? ""){

                DispatchQueue.main.async {
                    completion(thumbnail)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        
    }
    
    
}
