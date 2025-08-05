//
//  VideoPreviewView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 31/05/2025.
//


import SwiftUI

struct SegmentsEditingBar: View {
    @Environment(\.layoutDirection) var layoutDirection
    @ObservedObject var viewModel : MontageVM
   
    var body: some View {
        VStack{
            if viewModel.textSegmentSelectedID != nil && viewModel.audioSegmentSelectedID == nil{
                withAnimation {
                    TextSegmentsEditingBar(viewModel: viewModel)
                    
                }
            }
            if viewModel.audioSegmentSelectedID != nil && viewModel.textSegmentSelectedID == nil{
                withAnimation {
                    
                    AudioSegmentsEditingBar(viewModel: viewModel)
                }
            }
        }
        .background(.clear)
        
    }
}

#Preview {
    SegmentsEditingBar(viewModel: MontageVM())
        .background(Color("main-background"))
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .leftToRight )
    
    
}



