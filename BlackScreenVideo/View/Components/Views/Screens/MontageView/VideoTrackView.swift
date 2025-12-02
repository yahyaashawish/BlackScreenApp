//
//  AudioTrackView 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 16/11/2025.
//


import SwiftUI
struct VideoTrackView: View {
    @ObservedObject var viewModel : MontageVM

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach($viewModel.videoTrack) { segment in
                VideoSegmentView(vm: viewModel, segment: segment, isSelected: viewModel.videoSegmentSelectedID == segment.id)
                    .zIndex(viewModel.videoSegmentSelectedID == segment.id ? 1 : 0)
            }
        }
        .frame(height: 32)
        
    }
}
