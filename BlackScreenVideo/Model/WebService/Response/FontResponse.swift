//
//  FontItem.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//


import Foundation

struct FontResponse: Codable {
    let data: [FontResponseData]
    let page : PageInfoResponse

}

struct FontResponseData: Codable {
    let id: Int
    let name: String
    let file: String
    let preview: String
    let preview_image_width: Int
    let preview_image_height: Int
    let font_name: String
    
}
