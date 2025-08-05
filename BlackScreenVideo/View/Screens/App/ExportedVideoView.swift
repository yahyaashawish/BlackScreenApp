//
//  ExtractedVideoView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 08/07/2025.
//


//
//  SizeOptionView.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 01/02/2025.
//

import SwiftUI
import GoogleMobileAds

struct ExportedVideoView: View {
    @StateObject private var adViewModel = BannerAdVM()
    
    @Environment(\.requestReview) var requestReview
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel : MontageVM
    @State var presentVideoPlayer : Bool = false
    @State var showSavingSheet : Bool = false
//    var videoSize : VideoSize? = .square1_1
    var body: some View {
        GeometryReader { geometry in
            //            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)
            
            
            ZStack{
                AppBackground()
                VStack(spacing: 30){
                    HStack{
                        AppBackButton()
                        Text("Video")
                            .font(Font.medium24)
                            .foregroundStyle(Color("C3C3D8"))
                        Spacer()
                        
                    }
                    
                    GeometryReader { geo in
                        if let videoSize = viewModel.videoSize?.size{
                            let containerSize = geo.size
                            
                            let scale = min(containerSize.width / videoSize.width,
                                            containerSize.height / videoSize.height)
                            
                            let displaySize = CGSize(
                                width: videoSize.width * scale,
                                height: videoSize.height * scale
                            )
                            ZStack{
                                if viewModel.isExportingVideo {
                                    RoundedRectangle(cornerRadius : 5)
                                        .fill(Color.black)
                                        .frame(maxWidth: .infinity)
                                        .overlay {
                                            
                                            ZStack{
                                                ZStack(alignment: .bottom) {
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .fill(.white.opacity(0.5))
                                                        .frame(width: 56,height: 56)
                                                    
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .fill(.white)
                                                        .frame(width: 56,height: CGFloat(viewModel.exportProgress) * 56)
                                                }
                                                
                                                Text("\(viewModel.exportProgress * 100, specifier: "%.2f")%")
                                                    .font(Font.medium9)
                                                    .foregroundStyle(.black)
                                                
                                            }
                                            
                                            
                                            
                                        }
                                }else if !viewModel.isExportingVideo && viewModel.outputURL != nil{
                                    Button{
                                        self.presentVideoPlayer = true
                                    }label: {
                                        RoundedRectangle(cornerRadius : 5)
                                            .fill(Color.black)
                                            .frame(maxWidth: .infinity)
                                            .overlay {
                                                
                                                Circle()
                                                    .fill(Color("primary-color"))
                                                    .frame(width: 35, height: 34)
                                                    .overlay(
                                                        Image(systemName: "play.fill")
                                                            .font(.system(size: 18))
                                                            .foregroundStyle(.white)
                                                    )
                                                
                                                
                                                
                                            }
                                        
                                        
                                    }
                                }
                                
                                
                            }
                            .frame(width: displaySize.width, height: displaySize.height)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                         
                        }
                    }
                    .frame(height: 400)
                    
                    HStack{
                        if let finalVideoURL = viewModel.outputURL,let thumbImage = viewModel.generateThumbnail(),!viewModel.isExportingVideo{
                        FinalVideoButton(title: "Save Video", icon: "save-icon") {
                            showSavingSheet = true
                        }
                        
                            ShareLink(
                                item: finalVideoURL,
                                preview: SharePreview(
                                    "Exported Video",
                                    image: Image(uiImage: thumbImage)
                                    
                                )
                            ) {
                                VStack{
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color("27272F"))
                                        .frame(width: 95 , height: 72)
                                        .overlay {
                                            Image("share-icon")
                                        }
                                    
                                    Text("Share")
                                        .font(.regular16)
                                        .foregroundStyle(Color("A1A1B9"))
                                }
                            }
                            
                            FinalVideoButton(title: "Rate", icon: "star-icon") {
                                requestReview()
                            }
                        }
                       
                        
                        
                        
                    }
                    Spacer()
                }
                .padding(20)
            }
            
            
            
            
        }
        .navigationBarBackButtonHidden(true)
        .onAppear{
            Task {
                await viewModel.exportVideo()

            }
        }
        .onDisappear {
            viewModel.cancelVideoExporting()
        }
        .fullScreenCover(isPresented: $presentVideoPlayer) {
            if let url = viewModel.outputURL , let size = viewModel.videoSize?.size{
                ExportedVideoPlayerView(videoURL: url, videoSize: size )
            }
        }
        
        .alert(viewModel.savingVideoAlert.title, isPresented: $viewModel.presentAlert, actions: {
            if viewModel.savingVideoAlert == .videoSaved{
                Button("OK", role: .cancel) {
                    
                }
                
            }else if viewModel.savingVideoAlert == .videoSavingError{
                Button("Cancel", role: .cancel) {
                    
                }
                Button("Try again!") {
                    showSavingSheet = true
                    
                }
            }
            else if viewModel.savingVideoAlert == .videoExtractingError{
                Button("Cancel", role: .cancel) {
                   
                }
                Button("Try again!") {
                    Task{
                       await viewModel.exportVideo()
                    }
                    
                    
                }
            }
        }, message: {
                Text(viewModel.savingVideoAlert.message)
                .font(.medium12)
            
        })
        .environment(\.layoutDirection,  LanguageSetting.shared.isRightToLeft ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $showSavingSheet) {
            AddNewTextSegmentView(placeholder: "Video Title") { title in
                viewModel.saveVideo(with: title)
                
            }
            .presentationCornerRadius(20)
            .presentationDetents([.height(100)])
            .presentationBackground(.clear)
            
        }
        
    }
    
}


#Preview {
    NavigationStack{
        ExportedVideoView(viewModel: MontageVM())
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




