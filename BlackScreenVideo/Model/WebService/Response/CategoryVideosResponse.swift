//
//  Song.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 07/02/2025.
//


import Foundation



struct CategoryVideosResponse: Codable {
    let status : RequestStatusResponse
    let data : [BlackScreenVideo]
    let page : PageInfoResponse
}



struct BlackScreenVideo: Identifiable, Codable {
    let id: Int
    let thumbnail_url: String
    let video_url: String
    let name: String
    let category_id: Int
    let category_name: String
    let user_id: Int
    let username: String
    let likes_count: Int
    let views_count: Int
    let is_liked: Int


}

