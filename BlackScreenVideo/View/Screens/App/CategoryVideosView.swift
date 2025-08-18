//
//  VideoCategoriesView 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/07/2025.
//


import SwiftUI
import GoogleMobileAds

struct CategoryVideosView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @ObservedObject var appPath = AppPath.shared
    @StateObject private var adViewModel = BannerAdVM()
    @ObservedObject var viewModel : VideoCategoryVM
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                AppBackground()
                VStack(spacing: 35){
                    VStack{
                        ScrollView(.vertical) {
                            VStack{
                                VStack{
                                    if !viewModel.isFetchingVideos && viewModel.selectedCategory != nil{
                                        VideosCard(localizedTitle: "Most Popular",videos: viewModel.selectedCategory?.videos ?? [])
                                            .environment(\.layoutDirection,  layoutDirection)
                                    }
                                    
                                   
                                    if viewModel.isFetchingVideos{
                                        VideosCardSkeleton(isGrid: false,isForHome: false,isDoubleTitle: false)
                                            .environment(\.layoutDirection, layoutDirection)
                                        
                                    }
                                }
                                .padding(.vertical,20)
                                if adViewModel.isAdReceived {
                                    GeometryReader { adGeo in
                                        let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(adGeo.size.width)
                                        BannerView(adSize: adSize,isCollapsed: false, isTop: false,bannerVM : adViewModel)
                                    }
                                    .frame(height: 80)
                                }
                                VStack{
                                    if !viewModel.isFetchingVideos && !viewModel.selectedCategoryVideos.isEmpty{
                                        VideosCard(localizedTitle: "Recently Added",videos: viewModel.selectedCategoryVideos,isGrid: true,loadMoreAction: viewModel.fetchVideosForSelectedCategory)
                                        }
                                    
                                    if viewModel.isFetchingVideos{
                                           
                                            
                                            VideosCardSkeleton(isGrid: true,isForHome: true,isDoubleTitle: false)
                                                .environment(\.layoutDirection, layoutDirection)
                                        
                                        
                                        
                                    }
                                    
                                }
                                .padding(.vertical,20)

                                                               
                            }
                            
                        }
                        .scrollIndicators(.hidden)
                        .refreshable {
                            viewModel.fetchVideosForSelectedCategory(isNewCategory: true)
                        }
                    }
                    .padding(.top,10)
                    
                    
                    Spacer()


                    
                }
//                .padding(.horizontal,25)
            }
            
        }
        .onAppear {
            viewModel.fetchVideosForSelectedCategory(isNewCategory: true)
        }
        .onDisappear{
            viewModel.cancelCurrentTask()
        }
        .titleToolbar(staticTitle: viewModel.selectedCategory?.name ?? "All Videos")
        
        .navigationBarBackButtonHidden(true)

    }
    
    
    
    
    
    
    
    
}


#Preview {
    NavigationStack{
        CategoryVideosView(viewModel: VideoCategoryVM())
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}

