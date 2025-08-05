//
//  PageInfo.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 28/07/2025.
//

import Foundation

struct PageInfoResponse: Codable {
    let TotalRecords : Int
    let PageNo : Int
    let TotalPages : Int
    let PageSize : Int
}
