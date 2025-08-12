//
//  RequestStatusResponse 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 10/08/2025.
//


import Foundation

struct ToggleLikeResponse: Codable {
    let status: RequestStatusResponse
    let data : [BlackScreenVideo]
    let page : PageInfoResponse
    
}
