
import SwiftUI
import StoreKit
import GoogleMobileAds
struct MainView: View {
    @Environment(\.requestReview) var requestReview
    @Environment(\.layoutDirection) var layoutDirection
    @ObservedObject var appPath = AppPath.shared
    @StateObject private var adViewModel = BannerAdVM()
    @StateObject private var homeVideosVM = HomeReadyVideosVM()
    @State var showVideoCategories : Bool = false
    let developerURL = URL(string: "https://apps.apple.com/om/developer/ibrahim-shaqoura/id1254072921")!
    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .bottomLeading){
                AppBackground()
                VStack(spacing: 35){
                    HStack{
                        Text("Make fun now")
                            .font(.medium24)
                            .foregroundStyle(Color("primary-text-color"))
                        Spacer()
                        HStack{
                            Button{
                                UIApplication.shared.open(developerURL)
                            }label:{
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.grayBg)
                                    .frame(width: 40,height: 40)
                                    .overlay {
                                        Image("apps-icon")
                                    }
                            }
                            Button{
                                requestReview()
                            }label:{
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.grayBg)
                                    .frame(width: 40,height: 40)
                                    .overlay {
                                        Image("rate-icon")
                                    }
                            }
                            
                        }
                    }
                    ScrollView{
                        VStack(spacing:15){
                            
                            
                            NewVideoButton(isForLibraryView: false)
                            Button{
                                appPath.navigate(to: .videosLibrary)

                            }label: {
                                HStack(alignment:.center){
                                    VStack(alignment:.leading,spacing: 5){
                                        Text("Your Video Library")
                                            .font(.bold18)
                                            .foregroundStyle(.white)
                                        
                                        Text("Here you can find all the videos you made")
                                            .font(.regular10)
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.bottom,25)
                                    Spacer()
                                    Image("library-icon")
                                    
                                }
                                .padding(.horizontal,25)
                                .padding(.top,25)
                                .frame(height: 114)
                                .background(Color("gray-bg"))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                            
                        }
                        
                        
                        // videos card
                        VStack{
                            HStack{
                                Text("Most popular")
                                    .font(.medium24)
                                    .foregroundStyle(Color.primaryText)
                                Spacer()
                                Button{
                                    showVideoCategories = true
                                }label: {
                                    HStack{
                                        Text("All posts")
                                            .font(.medium14)
                                            .foregroundStyle(Color("9191A8"))
                                            .padding(.horizontal,20)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("gray-bg"), lineWidth: 1)
                                            .frame(height: 38)
                                    )
                                }
                            }
                           
                            VStack{
                                if homeVideosVM.isFetchingVideos{
                                    VideosCardSkeleton(isGrid: false,isForHome: true,isDoubleTitle: true)
                                        
                                        
                                        .padding(.top,0)
                                    
                                }
                                if !homeVideosVM.videos.isEmpty && !homeVideosVM.isFetchingVideos{
                                    withAnimation {
                                        VideosCard(videos: homeVideosVM.videos)
                                        .padding(.top,0)
                                        
                                        
                                    }
                                }
                                if !homeVideosVM.isFetchingVideos && homeVideosVM.videos.isEmpty && !homeVideosVM.isThereAnError{
                                    Text("No Videos Available")
                                        .font(Font.medium14)
                                        .foregroundStyle(Color("9191A8"))
                                }
                                
                            }
                            
                            
                           
                        }
                        
                        
                        
                        .padding(.top,25)
                        
                    }

                }
                .padding(.horizontal,25)
                
            }
            
            
        }

        .navigationBarBackButtonHidden(true)
        .onAppear{
            homeVideosVM.fetchHomeVideos()
        }
        .navigationDestination(isPresented: $showVideoCategories, destination: {
            VideoCategoriesView()
        })
        .safeAreaInset(edge: .bottom,alignment: .trailing) {
            if homeVideosVM.isThereAnError{
                ErrorToastView(message: "Something went wrong!") {
                    homeVideosVM.fetchHomeVideos()
                }
                .padding(20)
                
            }
        }
    }
        
    

    
}









#Preview {
    NavigationStack{
        MainView()
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




