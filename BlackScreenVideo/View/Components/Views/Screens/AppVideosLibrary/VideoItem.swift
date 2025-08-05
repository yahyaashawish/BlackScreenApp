//
//  VideoItem.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 03/08/2025.
//


//
//  BackgroundView.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 04/12/2024.
//

import SwiftUI

struct VideoItem: View {
    let video : Video
    let appLibraryVM : AppLibraryVM
    let action : () -> Void
    @State var thumbImage : UIImage? = nil
    @State var showDeleteConfirmation : Bool = false
    var videoURL : URL? {
        VideoFileManager.shared.getExistingVideoURL(key: video.name ?? "")
    }
    
    var body: some View {
        
        VStack{
            if let date = video.created_at , let title = video.title{
                
                HStack{
                    if let thumbImage = thumbImage {
                        Image(uiImage: thumbImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 119)
                            .clipShape(.rect(cornerRadius: 10))
                            .foregroundStyle(.gray)
                    }else{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black)
                            .frame(width: 100, height: 119)
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 5){
                        Text(title)
                            .font(.regular16)
                            .foregroundStyle(Color("A1A1B9"))
                        Text(appLibraryVM.formatDate(date))
                            .font(.regular10)
                            .foregroundStyle(Color("6C6C7B"))
                    }
                    
                    Spacer()
                }
                Divider()
            }
        }
        .swipeActions(allowsFullSwipe: false) {
            
            if let videoURL {
                ShareLink(
                    item: videoURL,
                    preview: SharePreview(
                        video.title ?? "Video Sharing",
                        image: Image(uiImage: thumbImage ?? UIImage(systemName: "play.circle")!)
                        
                    )
                ) {
                    SwipeActionButton(color: Color("34CC99"), icon: Image("share-video"))
                }
                .tint(Color("main-background"))
                
            }
            Button() {
                showDeleteConfirmation = true
            } label: {
                SwipeActionButton()
                
            }
            
            .tint(Color("main-background"))
            
           

            
            
        }
        
        .onTapGesture {
            action()
        }
        
        .onAppear {
            video.loadThumbImage { image in
                if let image = image {
                    thumbImage = image

                }else{
                    thumbImage = UIImage(named: "video-circle")
                }
            }
            
        }
        .alert("Are you sure you want to delete this video?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                
            }
            Button("Yes",role: .destructive) {
                appLibraryVM.deleteVideo(video)
            }
        }

    }
   

 
}

#Preview {
    VideoItem(video : Video(context: CoreDataHelper.shared.persistentContainer.viewContext),appLibraryVM: AppLibraryVM()){
        
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}
