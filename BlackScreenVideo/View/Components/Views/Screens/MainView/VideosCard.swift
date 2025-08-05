//
//  VideosCard.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 13/05/2025.
//


import SwiftUI
struct VideosCard: View {
    @Environment(\.layoutDirection) var layoutDirection

    var title : String? = nil
    var localizedTitle : LocalizedStringKey? = nil
    var titleColor : Color = Color("FFC72C")
    var btnTitle : LocalizedStringKey? = nil
    let videos : [BlackScreenVideo]
    var isGrid : Bool = false
    var btnAction : (() -> Void)? = nil
    @State var selectedVideoToPlay : BlackScreenVideo? = nil
    @State var showPlayer : Bool = false
    var body: some View {
        VStack{
            HStack{
                if let title{
                    Text(title)
                        .font(.medium18)
                        .foregroundStyle(titleColor)
                }
                
                if let localizedTitle {
                    Text(localizedTitle)
                        .font(.medium18)
                        .foregroundStyle(titleColor)
                }
               
                Spacer()
                if let btnTitle  = btnTitle{
                    Button{
                        btnAction?()
                    }label: {
                        HStack{
                            Text(btnTitle)
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
                
            }
            if !isGrid {
                ScrollView(.horizontal) {
                    HStack{
                        ForEach(videos, id: \.id){ video in
                            VideoItemView(video: video){
                                selectedVideoToPlay = video
                                showPlayer = true
                            }
                        }
                        
                    }
                }
            }else{
                ScrollView(.vertical) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 140)), count: 2), spacing: 10){
                        ForEach(videos, id: \.id){ video in
                            VideoItemView(video: video){
                                selectedVideoToPlay = video
                                showPlayer = true

                            }
                        }
                    }
                }
            }
            
        }
        .navigationDestination(isPresented: $showPlayer) {
            BlackScreenVideoPlayerView(videos: videos, startVideoID: selectedVideoToPlay?.id ?? videos[0].id)
                .environment(\.layoutDirection, layoutDirection)
        }
    }
    
}
struct VideoItemView: View {
    let video : BlackScreenVideo
    let action : () -> Void
    var body: some View {
        Button{
          action()
        }label: {
            VStack(alignment:.leading,spacing: 10){
                
                ZStack{
                    AsyncImage(url: URL(string: video.thumbnail_url)) { image in
                        image.resizable()
                            
                            
                    } placeholder: {
                        Rectangle()
                            .fill(.black)
                            .frame(width: 140,height: 168)

                    }
                    .frame(width: 140,height: 168)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                    
                        Image("play-video")
                    
                }
                VStack(alignment:.leading,spacing:5){
                        Text(video.name)
                            .font(.regular14)
                            .lineLimit(1)
                            .foregroundStyle(Color("video-title-color"))
                        

                    HStack{
                        
                            
                            Image("favorite-icon")
                            Text(String(video.likes_count))
                                .font(.regular10)
                                .lineLimit(1)
                                .foregroundStyle(Color("6C6C7B"))
                            

                    }
                    
                }
                Spacer()
            }
        }
    }
}
