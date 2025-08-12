
import SwiftUI
import BackgroundTasks
import GoogleMobileAds
import AdSupport
import VungleAdsSDK
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        
        InterfaceOrientationCoordinator.shared.supportedOrientations
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        AdMobConstants.requestIDFA{
            print("requestIDFA")
        }
        
        GADMobileAds.sharedInstance().start { status in
            print("SDK Status: \(status.adapterStatusesByClassName)")
        }
        VungleAds.initWithAppId(AdMobConstants.vungleID) { error in
            if  error != nil {
                print("Error initializing SDK")
            } else {
                print("Init is complete")
            }
        }
        VunglePrivacySettings.setGDPRStatus(true)
        VunglePrivacySettings.setGDPRMessageVersion("v1.0.0")
        
        //US
        VunglePrivacySettings.setCCPAStatus(true)
        
       
        return true
    }
    
   
}
