//
//  VideoPreviewView 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 24/07/2025.
//

import SwiftUI
struct VideoPreviewView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @ObservedObject var viewModel : MontageVM
    
    var body: some View {
        HStack(alignment: .bottom,spacing: 0) {
            
            VStack{
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
                            
                            
                            Rectangle()
                                .fill(Color.black)
                                .frame(maxWidth: .infinity)
                            
                            if let image = viewModel.currentTimeVideoImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            }
                            
                            if viewModel.isPreviewPlaying {
                                CustomVideoPlayer(player: viewModel.previewVideoPlayer)
                                    .frame(width: displaySize.width,height: displaySize.height,alignment: .center)
                            }
                           
                            
                            
                            
                            
                            
                            
                            if let segmentId = viewModel.textSegmentSelectedID  {
                                let segment = viewModel.textTracks
                                    .flatMap { $0 }.first { seg in
                                        seg.id == segmentId
                                    }
                                if let segment = segment{
                                    TextSegmentContentView(segment: segment,previewSize: displaySize,isSelected: true,isPreviewPlaying : false) { pos in
                                        viewModel.updateTextSegmentPosition(id: segmentId, to: pos)
                                    }
                                    .onTapGesture {
                                            withAnimation(.bouncy) {
                                                viewModel.selectTextSegment(segment: segment)
                                            }
                                        
                                    }
                                    
                                }
                                
                                
                                
                                
                            }else{
                                
                                
                                ForEach(viewModel.activeTexts, id: \.id) { segment in

                                    TextSegmentContentView(segment: segment,previewSize: displaySize,isSelected: segment.id == viewModel.textSegmentSelectedID,isPreviewPlaying : viewModel.isPreviewPlaying){ pos in
                                            viewModel.updateTextSegmentPosition(id: segment.id, to: pos)
                                            print(pos)
                                        }
                                        
                                        .onTapGesture {
                                            withAnimation(.bouncy) {
                                                viewModel.selectTextSegment(segment: segment)
                                            }
                                            
                                        }
                                        .transition(viewModel.isPreviewPlaying ? segment.transitionType.asAnyTransition : .opacity)
                                        .id(segment.id)

                                        
                                    
                                }
                            }
                            
                        }
                        .animation(.easeInOut,value: viewModel.currentTime)
                        .clipped()
                        .onAppear{
                            viewModel.previewSize = displaySize
                        }
                        .frame(width: displaySize.width, height: displaySize.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    
                }

            }
            //            .background(Color("1B1B22"))
            
            
        }
        .environment(\.layoutDirection,  .leftToRight )
        .frame(height: 320)
        
        
    }
}
#Preview {
    NavigationStack{
        MontageView(videoSize: .portrait9_16, initialSong: LocalSong(name: "test", duration: 20, url: URL.homeDirectory))
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}
