//
//  Song.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 07/02/2025.
//


import Foundation

struct ChromaVideosResponse: Codable {
    let status : RequestStatusResponse
    let data : [ChromaVideo]
    let page : PageInfoResponse
}




struct ChromaVideo: Codable ,Identifiable{
    let id : Int
    let thumbnail_url : String
    let video_url : String
    let name : String

    
   
}


