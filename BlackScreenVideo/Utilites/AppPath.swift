
import SwiftUI

enum AppRoute  : Hashable{
    case mainView
    case videosLibrary
    
   
    
}

final class AppPath : ObservableObject{
    private var navigationsCount = 0
   // private var adViewModel = InterstitialAdManager()
    private var adViewModel = InterstitialAd()
    
    static let shared = AppPath()
    
    @Published var path = NavigationPath()
    
    func navigate(to route: AppRoute) {
        path.append(route)
        navigationsCount+=1
//        if navigationsCount != 0 && navigationsCount % 2 == 0  {
//                adViewModel.loadAdAndShow {
//                    print("Ad shown")
//                }
//            
//            //adViewModel.showAd()
//        }
       
    }
    
    func resetToRoot() {
        path.removeLast(path.count)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    
    
}

struct AppDestinationRouteModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                    
                case .mainView:
                    MainView()
                case .videosLibrary:
                    AppVideosLibrary()
                }
            }
    }
}

extension View {
    func appDestinationRouteModifier() -> some View {
        self.modifier(AppDestinationRouteModifier())
    }
}
