import SwiftUI
import GoogleMobileAds

struct VideoCategoriesView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @ObservedObject var appPath = AppPath.shared
    @StateObject private var adViewModel = BannerAdVM()
    @StateObject private var viewModel : VideoCategoryVM = VideoCategoryVM()
    @State private var showCategoryDetails : Bool = false
    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .bottom){
                AppBackground()
                VStack(spacing: 35){
                    VStack{
                        ScrollView(.vertical) {
                            VStack{
                               
                                
                                let adPlacment = 3
                                
                                
                                ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { index, category in
                                    VStack{
                                        
                                            VideosCard(title: category.name, btnTitle: "All",videos: category.videos){
                                                viewModel.selectedCategory = category
                                                showCategoryDetails = true
                                            }
                                            
                                        
                                        
                                        
                                       
                                    }
                                    .padding(.vertical,10)
                                    .onAppear {
                                        if category.id == viewModel.categories.last?.id {
                                            
                                        }
                                    }
                                    if index % adPlacment == 0 {
                                        if adViewModel.isAdReceived {
                                            GeometryReader { adGeo in
                                                let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(adGeo.size.width)
                                                BannerView(adSize: adSize,isCollapsed: false, isTop: false,bannerVM : adViewModel)
                                            }
                                            .frame(height: 80)
                                        }
                                    }
                                    
                                }
                                if viewModel.isFetchingCategories{
                                    VStack{
                                        ForEach(0..<3, id: \.self) { _ in
                                            VideosCardSkeleton(isGrid: false,isForHome: false,isDoubleTitle: true)
                                                .padding(.vertical,10)
                                            
                                        }
                                        
                                    }
                                    
                                    .environment(\.layoutDirection,  layoutDirection)
                                    
                                    Spacer()
                                    
                                    
                                    
                                }
                                
                                
                            }
                            GeometryReader { geometry in
                                
                                Color.clear
                                
                                    .onChange(of: geometry.frame(in: .global).minY) { _,newMinY in
                                        let screenHeight = UIScreen.main.bounds.height
                                        if newMinY <= screenHeight {
                                            viewModel.fetchCategoriesForNextPage()
                                        }
                                    }
                            }
                            .frame(height: 1)
                        }
                        .refreshable {
                            viewModel.fetchCategoriesForNextPage(reloadData: true)
                        }
                        .scrollIndicators(.hidden)
                        
                    }
                    .padding(.top,10)
                    
                    
                    
                
                    
                }
                
            }
            .onAppear {
                if viewModel.categories.isEmpty{
                    viewModel.fetchCategoriesForNextPage()
                }
            }
            
        }
        
        .titleToolbar(title: "Ready-made videos")
        
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showCategoryDetails, destination: {
            CategoryVideosView(viewModel: viewModel)
                .environment(\.layoutDirection,  layoutDirection)

        })
        
    }
    
    
    
    
    
    
    
    
}









#Preview {
    NavigationStack{
        VideoCategoriesView()
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




