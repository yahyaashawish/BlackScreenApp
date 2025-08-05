//
//  AudioTrackView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 24/07/2025.
//

import SwiftUI
struct AudioTrackView: View {
    @ObservedObject var viewModel : MontageVM

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach($viewModel.audioSegments) { segment in
                AudioSegmentView(vm: viewModel, segment: segment, isSelected: viewModel.audioSegmentSelectedID == segment.id)
            }
        }
        .frame(height: 32)
        
    }
}
