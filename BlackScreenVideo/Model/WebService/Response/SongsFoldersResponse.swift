//
//  Song.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 07/02/2025.
//


import Foundation
struct SongsFoldersResponse: Codable {
    let status : RequestStatusResponse
    let data : [SongsFolder]
}




struct SongsFolder: Identifiable, Codable {
    let id: Int
    let name: String
    let files_count: Int

}
