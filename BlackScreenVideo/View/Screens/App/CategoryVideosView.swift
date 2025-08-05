//
//  VideoCategoriesView 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/07/2025.
//


import SwiftUI
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
                                    VideosCard(localizedTitle: "Most Popular",videos: viewModel.selectedCategory?.videos ?? [])
                                        .environment(\.layoutDirection,  layoutDirection)

                                    if viewModel.selectedCategory == nil || viewModel.selectedCategory?.videos.count ?? 0 == 0{
                                        Text("No Videos Available")
                                            .font(Font.medium14)
                                            .foregroundStyle(Color("9191A8"))
                                    }
                                }
                                .padding(.vertical,20)

                                VStack{
                                    VideosCard(localizedTitle: "Recently Added",videos: viewModel.selectedCategoryVideos,isGrid: true)
                                    
                                    if viewModel.isFetchingVideos{
                                        VideosCardSkeleton(isGrid: true,isForHome: true,isDoubleTitle: false)
                                            .environment(\.layoutDirection, layoutDirection)
                                        
                                    }
                                    if !viewModel.isFetchingVideos && viewModel.selectedCategoryVideos.isEmpty && !viewModel.isThereAnError{
                                        Text("No Videos Available")
                                            .font(Font.medium14)
                                            .foregroundStyle(Color("9191A8"))
                                    }
                                }
                                .padding(.vertical,20)

                                                               
                            }
                            
                        }
                    }
                    .padding(.top,10)
                    
                    
                    Spacer()


                    
                }
                .padding(.horizontal,25)
            }
            .onAppear {
                viewModel.fetchVideosForSelectedCategory()
            }
            .onDisappear{
                viewModel.cancelCurrentTask()
            }
        }
        
        .titleToolbar(staticTitle: viewModel.selectedCategory?.name ?? "All Videos")
        
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom,alignment: .trailing) {
            if viewModel.isThereAnError{
                ErrorToastView(message: "Something went wrong!") {
                    viewModel.fetchVideosForSelectedCategory()
                }
                .padding(20)
                
            }
        }
    }
    
    
    
    
    
    
    
    
}


#Preview {
    NavigationStack{
        CategoryVideosView(viewModel: VideoCategoryVM())
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}

