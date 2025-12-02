//
//  AppSongsLibraryView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 17/05/2025.
//

import SwiftUI

struct AppLibraryVideosPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.layoutDirection) var layoutDirection
    let onSelectVideo: (LocalVideo) -> Void
    @StateObject var viewModel = ChromaVideosVM()
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .bottom){
                AppBackground()
                VStack{
                    HStack{
                        Text("Chroma videos")
                            .font(.medium18)
                            .foregroundStyle(Color("C3C3D8"))
                        Spacer()
                        Button{
                            dismiss()
                        }label: {
                            Image("circle-close")
                        }
                    }
                    .padding(.bottom,20)
                    if viewModel.isFetchingVideos && viewModel.videos.isEmpty {
                        Spacer()
                        Spinner()
                        
                        
                    }
                    if !viewModel.videos.isEmpty{
                        ScrollView {
                            
                            VStack {
                                
                                LazyVGrid(columns: [.init(spacing: 20), .init(spacing: 20)]) {
                                    ForEach(viewModel.videos,id: \.id) { video in
                                        ChromaVideoView(video: video, isSelected: viewModel.selectedVideoId == video.id,playingVideo: $viewModel.playVideo)
                                            .onTapGesture {
                                                if VideoDownloadManager.shared.isVideoDownloaded(id: video.id){
                                                    viewModel.toogleSelectVideo(video)
                                                }
                                            }
                                        
                                    }
                                }
                                
                                
                                if viewModel.pageNum > 1 && viewModel.hasMorePages && viewModel.isFetchingVideos == false{
                                    Button {
                                        viewModel.fetchChromaVideos()
                                    } label: {
                                        Text("More")
                                            .font(.hevay16)
                                            .foregroundStyle(Color("A1A1B9"))
                                            .padding(.vertical,5)
                                            .padding(.horizontal,10)
                                        
                                            .background{
                                                RoundedRectangle(cornerRadius: 18)
                                                    .fill(.clear)
                                                    .strokeBorder(Color("A1A1B9"), lineWidth: 2)

                                            }

                                    }
                                    .padding(30)
                                }
                                if viewModel.isFetchingVideos && !viewModel.videos.isEmpty  {
                                    Spinner()
                                        .padding(30)

                                    
                                }
                            }
                            .padding(.bottom,60)
                            
                        }
                        .scrollIndicators(.hidden)
                        
                    }
                        
                        
                    
                    Spacer()
                                        
                }
                .padding(20)
                
                if viewModel.selectedVideoId != 0 {
                    if let selectedVideoURL = VideoDownloadManager.shared.localFileURL(for: viewModel.selectedVideoId){
                        ChooseVideoButton{
                            let localVideo = LocalVideo(video_url: selectedVideoURL, name: viewModel.selectedVideo?.name ?? "")
                            onSelectVideo(localVideo)
                        }
                    }
                    
                }
                
                
            }
            

        }
        .onAppear {
            viewModel.fetchChromaVideos()
        }
        .fullScreenCover(item: $viewModel.playVideo) { video in
            ChromaVideoPageView(video:video,onSelectVideo: onSelectVideo)
                .environment(\.layoutDirection, layoutDirection)
        }
       
    }
}
struct ChromaVideoView : View {
    @ObservedObject var downloadManager = VideoDownloadManager.shared

    let video : ChromaVideo
    let isSelected: Bool
    @State var isVideoDownloading: Bool = false
    @Binding var playingVideo: ChromaVideo?
    var isVideoDownloaded: Bool {
        downloadManager.isVideoDownloaded(id: video.id)
    }
    var body: some View {
        
            ZStack{
                VStack(alignment: .leading){
                    ZStack{
                        AsyncImage(url: URL(string: video.thumbnail_url)) { image in
                            image
                                .resizable()
                        } placeholder: {
                            SkeletonView(Rectangle())
                        }
                       
                        if isSelected {
                            Rectangle()
                                .fill(Color("4A4AFF").opacity(0.6))
                                .overlay {
                                    Image("check-icon-2")
                                        .resizable()
                                    
                                        .frame(width: 16, height: 13)
                                }
                        }else{
                            if isVideoDownloaded {
                                Button {
                                    playingVideo = video
                                } label: {
                                    Image(systemName: "play.fill")
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal,5)
                                }

                                
                            }else{
                                if isVideoDownloading {
                                    Button {
                                        downloadManager.cancelDownload(for: video.id)
                                        withAnimation {
                                            isVideoDownloading = false
                                        }
                                    } label: {
                                        let progress = $downloadManager.downloadProgress[video.id]
                                        CircleProgressBarWithCancelButton(progress:  progress)
                                            .padding(.horizontal,5)
                                    }
                                    
                                    
                                    
                                }else{
                                    Button {
                                        
                                        if let url = URL(string: video.video_url) {
                                            downloadManager.downloadVideo(id: video.id, from: url)
                                            withAnimation {
                                                isVideoDownloading = true
                                            }
                                        }else{
                                            ErrorHandler.shared.presentError(error: .somethingWentWrong)
                                        }
                                        
                                        
                                    } label: {
                                        Image(systemName: "arrow.down.to.line.circle.fill")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal,5)
                                    }
                                    
                                    
                                    
                                }
                            }
                        }
                    }
                    
                    .frame(width: 150,height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(video.name)
                        .foregroundStyle(Color("A1A1B9"))
                        .font(.regular14)
                        .lineLimit(1)
                    
                }
                
                
                
                
            }

        }

    
}
struct ChooseVideoButton: View {
    let action: () -> Void
    var body: some View {
        Button{
            action()
        }label: {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("4A4AFF"))
                .frame(height: 52)
                .padding(20)
                .overlay {
                    Text("Select background")
                        .foregroundStyle(Color("16161D"))
                        .font(.medium18)
                        
                }
            
        }
    }
}

#Preview {
    AppLibraryVideosPickerView(){ video in
        
    }
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
}

