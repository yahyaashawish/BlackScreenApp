//
//  VideoCategoryRequest.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 28/07/2025.
//

import Foundation

struct VideoCategoryResponse: Codable {
    let status : RequestStatusResponse
    let data : [VideoCategory]
}


struct VideoCategory : Identifiable, Codable {
    let id: Int
    let name: String
    let videos: [BlackScreenVideo]
    
    
}
