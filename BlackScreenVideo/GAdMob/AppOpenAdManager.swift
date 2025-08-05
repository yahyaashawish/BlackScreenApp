//
//  AppOpenAdManager.swift
//
//  Created by Yahya A Shawish on 22/12/2024.
//

import SwiftUI
import GoogleMobileAds
class AppOpenAdManager: NSObject {
  var appOpenAd: GADAppOpenAd?
  var isLoadingAd = false
  var isShowingAd = false

  static let shared = AppOpenAdManager()

  private func loadAd() async {
    // TODO: Implement loading an ad.
      if isLoadingAd || isAdAvailable() {
          return
      }
      isLoadingAd = true
      
      do {
          appOpenAd = try await GADAppOpenAd.load(
            withAdUnitID: AdMobConstants.openAdID, request: GADRequest())
      } catch {
          print("App open ad failed to load with error: \(error.localizedDescription)")
      }
      isLoadingAd = false
  }

  func showAdIfAvailable() {
      
    // TODO: Implement showing an ad.
      guard !isShowingAd else { return }
      print("is showing ad \(isShowingAd)")
      // If the app open ad is not available yet but is supposed to show, load
      // a new ad.
      if !isAdAvailable() {
          Task {
              await loadAd()
          }
          return
      }
      
      if let ad = appOpenAd {
          isShowingAd = true
          ad.present(fromRootViewController: nil)
      }
  }

  private func isAdAvailable() -> Bool {
    // Check if ad exists and can be shown.
    return appOpenAd != nil
  }
}
