//
//  BannerAdViewModel 2.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 28/12/2024.
//


import SwiftUI

class ErrorHandler: ObservableObject {
    @Published var isThereAnError: Bool = false
    var error : AppError? = nil
    var errorAction : (() -> Void)? = nil

    static let shared = ErrorHandler()
    
    func presentError(error: AppError, action: (() -> (Void))? = nil) {
        resetError()
        self.error = error
        self.errorAction = action
        DispatchQueue.main.async{
            withAnimation(.easeInOut) {
                self.isThereAnError = true
            }
        }
    }
    
    func pushAlert(alert: AppError) {
        resetError()
        self.error = alert
        DispatchQueue.main.async{
            withAnimation(.easeInOut) {
                self.isThereAnError = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.resetError()
        })
    }
    
    func dismissError() {
        DispatchQueue.main.async{
            withAnimation(.easeInOut) {
                self.isThereAnError = false
            }
        }
        
    }
    
    func resetError() {
        dismissError()
        self.error = nil
        self.errorAction = nil
    }
}

enum AppError {
    case noInternet
    case internetBecomeActive
    case fetchVideosFailed
    case cannotAddLikeToVideo
    case cannotRemoveLikeFromVideo
    case fetchSongsFaild
    case fetchChromaVideosFaild
    case somethingWentWrong
    var title : LocalizedStringKey {
        switch self {
        case .noInternet:
            return "No Internet Connection!"

        case .fetchVideosFailed:
            return "Fetching Videos Failed!"
        case .cannotAddLikeToVideo:
            return "Adding Like Failed!"
            
        case .internetBecomeActive:
            return "Internet Connection Restored!"
            
        case .cannotRemoveLikeFromVideo:
            return "Removing Like Failed!"
            
        case .fetchSongsFaild:
            return "Fetching Songs Failed!"

        case .fetchChromaVideosFaild:
            return "Fetching Chroma Videos Failed!"
         
        case .somethingWentWrong:
            return "Something Went Wrong!"
            
        }
    }
    
    var message : LocalizedStringKey {
        switch self {
        case .noInternet:
            return ""
        case .internetBecomeActive:
            return ""

        case .somethingWentWrong:
            return ""
            
        default:
            return "Make Sure Your Internet Connection Is Active"

        }
    }
    
    var icon :  some View {
        switch self {
        case .noInternet:
            Image(systemName: "wifi.slash")
                .foregroundColor(.gray)
            
        case .internetBecomeActive:
            Image(systemName: "wifi")
                .foregroundColor(.green)

        default:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

        }
    }
}
