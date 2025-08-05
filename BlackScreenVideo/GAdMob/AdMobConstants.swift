//
//  AdMobConstants.swift
//
//  Created by Yahya A Shawish on 22/12/2024.
//

import AppTrackingTransparency
import AdSupport
struct AdMobConstants {
    static let openAdID = "ca-app-pub-3940256099942544/5575463023"
    static let bannerAdID = "ca-app-pub-3940256099942544/2435281174"
    static let interstitialAdAdID = "ca-app-pub-3940256099942544/4411468910"
    static let vungleID = "6734a39c640cc01ab98abf00"
    
    
    static func requestIDFA(onDone: @escaping () -> Void, tryCount: Int = 0) {
        DispatchQueue.main.async {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    // Tracking authorization completed. Start loading ads here.
                    // loadAd()
                    if status == .notDetermined && tryCount <= 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            requestIDFA(onDone: onDone, tryCount: tryCount + 1)
                        }
                    } else {
                        DispatchQueue.main.async {
                            onDone()
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
                DispatchQueue.main.async {
                    onDone()
                }
            }
        }
    }
    
}
