//
//  BannerAdViewModel 2.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 28/12/2024.
//


import SwiftUI

class BannerAdVM: ObservableObject {
    @Published var isAdReceived: Bool = true
    
    func didReceiveAd() {
        isAdReceived = true
    }
    
    func didNotReceiveAd() {
        isAdReceived = false
    }
}
