//
//  VideoSize.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 01/02/2025.
//

import SwiftUI
enum VideoSize : String , CaseIterable{
    case square1_1 = "1:1"
    case portrait4_5 = "4:5"

    case landscape16_9 = "16:9"
    case portrait9_16 = "9:16"

    case landscape4_3 = "4:3"
    case portrait3_4 = "3:4"
    
    
    var size: CGSize {
        switch self {
        case .square1_1:
            //1080 x 1080
            return CGSize(width: 1080, height: 1080)
        case .landscape16_9:
            //1920 x 1080
            return CGSize(width: 1920, height: 1080)
        case .landscape4_3:
            //1024 x 768
            return CGSize(width: 1024, height: 768)
        case .portrait4_5:
            //1080 x 1350
            return CGSize(width: 1080, height: 1350)
        case .portrait9_16:
            //1080 x 1920
            return CGSize(width: 1080, height: 1920)
        case .portrait3_4:
            //900 x 1200
            return CGSize(width: 900, height: 1200)

        }
    }
    
    var icon : Image {
        switch self {
        case .square1_1:
            return Image("rect-11")
        case .landscape16_9:
            return Image("rect-169")

        case .landscape4_3:
            return Image("rect-43")

        case .portrait4_5:
            return Image("rect-45")

        case .portrait9_16:
            return Image("rect-916")

        case .portrait3_4:
            return Image("rect-34")

        }
    }
    
    var description: LocalizedStringKey {
        switch self {
        case .square1_1:
            return "(Instagram, twitter, facebook)"
            
        case .portrait4_5:
            return "(Instagram, facebook)"
            
        case .landscape16_9:
            return "(Youtube, twitter, facebook)"

        case .portrait9_16:
            return "(Story)"
            
        case .landscape4_3:
            return ""
            
        case .portrait3_4:
            return ""

        }
    }
    
}
