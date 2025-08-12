//
//  BannerView.swift
//
//  Created by Yahya A Shawish on 28/12/2024.
//


import Foundation
import GoogleMobileAds
import UIKit
import SwiftUI

struct BannerView: UIViewRepresentable {
    let adSize: GADAdSize
    let isCollapsed: Bool
    let isTop : Bool
    var bannerVM : BannerAdVM? = nil
    
    func makeUIView(context: Context) -> UIView {
        // Wrap the GADBannerView in a UIView. GADBannerView automatically reloads a new ad when its
        // frame size changes; wrapping in a UIView container insulates the GADBannerView from size
        // changes that impact the view returned from makeUIView.
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }
    
    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }
    // [END create_banner_view]
    
    // [START create_banner]
    class BannerCoordinator: NSObject, GADBannerViewDelegate {
        
        private(set) lazy var bannerView: GADBannerView = {
            let banner = GADBannerView(adSize: parent.adSize)
            // [START load_ad]
            banner.adUnitID = AdMobConstants.bannerAdID
            let request = GADRequest()
            
            if parent.isCollapsed {
                let extras = GADExtras()
                if parent.isTop {
                    extras.additionalParameters = ["collapsible" : "top"]
                }else{
                    extras.additionalParameters = ["collapsible" : "bottom"]
                    
                }
                request.register(extras)
            }
            banner.load(request)
            // [END load_ad]
            // [START set_delegate]
            banner.delegate = self
            // [END set_delegate]
            return banner
        }()
        
        let parent: BannerView
        
        init(_ parent: BannerView) {
            self.parent = parent
        }
        // [END create_banner]
        
        // MARK: - GADBannerViewDelegate methods
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Banner ad received!")
            parent.bannerVM?.didReceiveAd()
            
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner Ad failed to load: \(error)")
            parent.bannerVM?.didNotReceiveAd()
            
        }
    }
}
