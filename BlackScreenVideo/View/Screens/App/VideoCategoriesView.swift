import SwiftUI
struct VideoCategoriesView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @ObservedObject var appPath = AppPath.shared
    @StateObject private var adViewModel = BannerAdVM()
    @StateObject private var viewModel : VideoCategoryVM = VideoCategoryVM()
    @State private var showCategoryDetails : Bool = false
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                AppBackground()
                VStack(spacing: 35){
                    VStack{
                        ScrollView(.vertical) {
                            VStack{
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
                                
                                ForEach(viewModel.categories, id: \.id){ category in
                                    VStack{
                                        VideosCard(title: category.name, btnTitle: "All",videos: category.videos){
                                            viewModel.selectedCategory = category
                                            showCategoryDetails = true
                                        }
                                        
                                        if category.videos.isEmpty && !viewModel.isFetchingCategories && !viewModel.isThereAnError{
                                            Text("No Videos Available")
                                                .font(Font.medium14)
                                                .foregroundStyle(Color("9191A8"))
                                        }
                                    }
                                    .padding(.vertical,10)

                                    
                                }
                                
                                
                            }
                            
                        }
                        .scrollIndicators(.hidden)
                        
                    }
                    .padding(.top,10)
                    
                    
                    
                
                    
                }
                .padding(.horizontal,25)
            }
            .onAppear {
                viewModel.fetchCategories()
            }
        }
        
        .titleToolbar(title: "Ready-made videos")
        
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showCategoryDetails, destination: {
            CategoryVideosView(viewModel: viewModel)
                .environment(\.layoutDirection,  layoutDirection)

        })
        .safeAreaInset(edge: .bottom,alignment: .trailing) {
            if viewModel.isThereAnError{
                ErrorToastView(message: "Something went wrong!") {
                    viewModel.fetchCategories()
                }
                .padding(20)
                
            }
        }
    }
    
    
    
    
    
    
    
    
}









#Preview {
    NavigationStack{
        VideoCategoriesView()
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




