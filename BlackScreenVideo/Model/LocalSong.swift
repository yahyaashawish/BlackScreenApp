//
//  Song.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 07/02/2025.
//


import Foundation


struct LocalSong: Identifiable , Equatable {
    let id : UUID = UUID()
    let name: String
    let duration: Int
    let url: URL
}

