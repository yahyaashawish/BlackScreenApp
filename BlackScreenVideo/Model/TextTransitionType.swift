//
//  Transition.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 13/02/2025.
//

import SwiftUI
enum TextTransitionType: String, CaseIterable, Identifiable {
    case enterFromRight
    case enterFromLeft
    case enterFromTop
    case enterFromBottom
    case enterFromTopRight
    case enterFromTopLeft
    case enterFromBottomRight
    case enterFromBottomLeft
    case fade
    case none
    var id: String { rawValue }
    
    var icon : String {
        switch self {
        case .enterFromRight :
            return "trans-right"
        case .enterFromLeft:
            return "trans-left"
        case .enterFromTop:
            return "trans-top"
        case .enterFromBottom:
            return "trans-btm"
        case .enterFromTopRight:
            return "trans-top-right"
        case .enterFromTopLeft:
            return "trans-top-left"
        case .enterFromBottomRight:
            return "trans-btm-right"
        case .enterFromBottomLeft:
            return "trans-btm-left"
        case .fade:
            return "trans-fade"
            
        case .none:
            return ""
        }
    }
    
    var asAnyTransition: AnyTransition {
        switch self {
        case .enterFromRight: return .asymmetric(insertion: .move(edge: .trailing), removal: .opacity)
        case .enterFromLeft: return .asymmetric(insertion: .move(edge: .leading), removal: .opacity)
        case .enterFromTop: return .asymmetric(insertion: .move(edge: .top), removal: .opacity)
        case .enterFromBottom: return .asymmetric(insertion: .move(edge: .bottom), removal: .opacity)
        case .enterFromTopRight: return .asymmetric(insertion: .move(edge: .top).combined(with: .move(edge: .trailing)), removal: .opacity)
        case .enterFromTopLeft: return .asymmetric(insertion: .move(edge: .top).combined(with: .move(edge: .leading)), removal: .opacity)
        case .enterFromBottomRight: return .asymmetric(insertion: .move(edge: .bottom).combined(with: .move(edge: .trailing)), removal: .opacity)
        case .enterFromBottomLeft: return .asymmetric(insertion: .move(edge: .bottom).combined(with: .move(edge: .leading)), removal: .opacity)
        case .fade: return .opacity
        case .none: return .identity
        }
    }
}
