//
//  InterstitialAdViewModel.swift
//
//  Created by Yahya A Shawish on 24/12/2024.
//


import GoogleMobileAds
import SwiftUI

class InterstitialAdManager: NSObject, ObservableObject {
    private var interstitial: GADInterstitialAd?
    @Published var isAdReady: Bool = false

    func loadAd() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: AdMobConstants.interstitialAdAdID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                self?.isAdReady = false
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
            self?.isAdReady = true
        }
    }

    func showAd() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No active root view controller found.")
            return
        }
        guard let interstitial = interstitial else {
            return
        }
        interstitial.present(fromRootViewController: rootViewController)
    }
}

extension InterstitialAdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad was dismissed.")
        self.isAdReady = false // Optionally reload the ad after it's dismissed.
    }

    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("Ad recorded an impression.")
    }

    func adDidFailToPresentFullScreenContent(_ ad: GADFullScreenPresentingAd, withError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        self.isAdReady = false
    }
}
