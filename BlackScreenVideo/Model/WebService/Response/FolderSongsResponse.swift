//
//  Song.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 07/02/2025.
//


import Foundation

struct FolderSongsResponse: Codable {
    let status : RequestStatusResponse
    let data : [Song]
    let page : PageInfoResponse
}




struct Song: Identifiable, Codable {
    let id: Int
    let name: String
    let duration: Int
    let thumbnail : String
    let file: String
    let folder_id: Int

}

