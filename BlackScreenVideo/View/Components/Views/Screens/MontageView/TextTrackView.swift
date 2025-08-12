//
//  TextTrackView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 24/07/2025.
//

import SwiftUI
struct TextTrackView: View {
    @ObservedObject var viewModel : MontageVM
    var body: some View {
        ScrollViewReader { proxy in
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(viewModel.textTracks.indices, id: \.self) { trackIndex in
                        ZStack(alignment: .topLeading) {
                            ForEach($viewModel.textTracks[trackIndex]) { segment in
                                TextSegmentView(vm: viewModel, seg: segment,isSelected: viewModel.textSegmentSelectedID == segment.id)
                                    .id("text_segment_\(segment.id)")

                            }
                        }
                        .frame(height: viewModel.textSegmentSelectedID != nil ? 45 : 35) // fixed height for each track
                    }
                }
                
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(height:180)

                        .onTapGesture(coordinateSpace: .named("timelineScroll")) { location in
                            guard !viewModel.isPreviewPlaying else {return}
                            
                            let tappedX = location.x
                            let actualXInTimeline = viewModel.scrollOffset + tappedX
                            let selectedTime = max(0, actualXInTimeline / viewModel.pixelsPerSecond)
                            viewModel.currentTime = selectedTime*viewModel.timeScale
                            viewModel.tapX = tappedX
                        }
                )
                .onChange(of: viewModel.textTracks) { _, newTrackData in
                     
                    if let lastSegmentId = viewModel.lastSegmentID {
                        guard viewModel.textSegmentSelectedID == nil else {return}
                        proxy.scrollTo("text_segment_\(lastSegmentId)", anchor: .leading)
                    }
                }
                .onChange(of: viewModel.textSegmentSelectedID) { _, newSegmentId in
                    if let newSegmentId {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            withAnimation {
                                proxy.scrollTo("text_segment_\(newSegmentId)", anchor: .leading)
                            }
                            
                        }
                        
                    }
                       
                    
                }
                
            }
            .frame(height:110)
            
        }
        
        
        
    }
}


#Preview {
    NavigationStack{
        MontageView(videoSize: .portrait9_16, initialSong: LocalSong(name: "test", duration: 20, url: URL.homeDirectory))
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}
