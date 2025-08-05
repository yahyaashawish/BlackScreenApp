//
//  InterstitialAd.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 22/02/2025.
//


import GoogleMobileAds
import SwiftUI

class InterstitialAd: NSObject, GADFullScreenContentDelegate, ObservableObject {
    private var interstitial: GADInterstitialAd?
    var adUnitID = AdMobConstants.interstitialAdAdID // Replace with your AdMob Interstitial Ad Unit ID
    var onAdDismissed: (() -> Void)?  // Closure to handle post-ad action
    

    func loadAd() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }

    func showAd() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No active root view controller found.")
            return
        }
        
        if let interstitial = interstitial {
            interstitial.present(fromRootViewController: rootViewController)
        } else {
            print("Ad not ready")
            onAdDismissed?() // If ad is not ready, call the event immediately
        }
    }
    
    func loadAdAndShow(onAdDismissed: @escaping () -> Void){
        self.onAdDismissed = onAdDismissed
        loadAd()
        if interstitial != nil {
            showAd()
        }
    }
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        onAdDismissed?() // Call the event handler after ad dismissal
    }
}

