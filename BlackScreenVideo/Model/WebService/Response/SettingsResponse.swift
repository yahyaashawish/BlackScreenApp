//
//  Song.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 07/02/2025.
//


import Foundation

struct SettingsResponse: Codable {
    let status : RequestStatusResponse
    let data : Setting
}


struct Setting: Codable {
    let can_share: Bool
    let enable_facebook_login: Bool
    let show_music: Bool
    let show_share: Bool
}
