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
        withAnimation(.easeInOut) {
            self.isThereAnError = true
        }
    }
    
    func pushAlert(alert: AppError) {
        resetError()
        self.error = alert
        withAnimation(.easeInOut) {
            self.isThereAnError = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.resetError()
        })
    }
    
    func dismissError() {
        withAnimation(.easeInOut) {
            self.isThereAnError = false
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

        }
    }
    
    var message : LocalizedStringKey {
        switch self {
        case .noInternet:
            return ""
        case .fetchVideosFailed:
            return "Make Sure Your Internet Connection Is Active"
        case .cannotAddLikeToVideo:
            return "Make Sure Your Internet Connection Is Active"
        case .internetBecomeActive:
            return ""

        case .cannotRemoveLikeFromVideo:
            return "Make Sure Your Internet Connection Is Active"
        }
    }
    
    var icon :  some View {
        switch self {
        case .noInternet:
            Image(systemName: "wifi.slash")
                .foregroundColor(.gray)
            
        case .fetchVideosFailed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
        case .cannotAddLikeToVideo:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
        case .internetBecomeActive:
            Image(systemName: "wifi")
                .foregroundColor(.green)
        case .cannotRemoveLikeFromVideo:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

        }
    }
}
