//
//  VideoPreviewView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 31/05/2025.
//


import SwiftUI
enum TextEditingTab : LocalizedStringKey , CaseIterable{
    case delete = "Delete"
    case edit = "Text"
    case transition = "Transition"
    case fontType = "Font type"
    case background = "Filling"
    case color = "Color"
    case opacity = "Opacity"
    case shadow = "Shadow"
    case surroundColor = "Surround"
    
    var icon : String {
        switch self {
        case .transition:
            return "transition-icon"
        case .fontType:
            return "font-type-icon"
        case .background:
            return "background-icon"
        case .color:
            return "color-icon"
        case .opacity:
            return "opacity-icon"
        case .shadow:
            return "shadow-icon"
        case .surroundColor:
            return "font-type-icon"
        case .delete:
            return "trash-icon"
        case .edit:
            return "font-type-icon"
        }
    }
}

struct TextSegmentsEditingBar: View {
    @Environment(\.layoutDirection) var layoutDirection
    @State var selectedTab : TextEditingTab? = nil
    @ObservedObject var viewModel : MontageVM
    //    @State var segment : TextSegment? = TextSegment(content: "test", startTime: 30, duration: 555)
    var body: some View {
        VStack(spacing:0){
            
            if let segmentId = viewModel.textSegmentSelectedID {
                if let trackIndex = viewModel.textTracks.firstIndex(where: { $0.contains(where: { $0.id == segmentId }) }){
                    
                    if let segmentIndex = $viewModel.textTracks[trackIndex].firstIndex(where: { seg in
                        seg.id == segmentId
                    }){
                        let segment = $viewModel.textTracks[trackIndex][segmentIndex]
                        
                        if selectedTab != nil {
                            
                            VStack(spacing : 0){
                                Spacer()
                                
                                Rectangle()
                                    .fill(Color("31313A"))
                                    .frame(height: 2)
                                
                                switch selectedTab {
                                case .transition:
                                    TransitionTabView(textSegment: segment,applyOnAll: viewModel.applyTransitionOnAllTextSegments)
                                case .fontType:
                                    TextSegmentFontsView(textSegment: segment,applyOnAll: viewModel.applyFontOnAllTextSegments)
                                    //TransitionTabView(textSegment: $testTextSegment)
                                case .background:
                                    // TransitionTabView(textSegment: $testTextSegment)
                                    TextSegmentColorTabView(textSegment: segment, type: .background, applyOnAll: viewModel.applyBackgroundOnAllTextSegments)
                                    
                                case .color:
                                    // TransitionTabView(textSegment: $testTextSegment)
                                    TextSegmentColorTabView(textSegment: segment, type: .text, applyOnAll: viewModel.applyBackgroundOnAllTextSegments)
                                    
                                case .opacity:
                                    // TransitionTabView(textSegment: $testTextSegment)
                                    OpacityTabView(textSegment: segment)
                                    
                                case .shadow:
                                    // TransitionTabView(textSegment: $testTextSegment)
                                    TextSegmentShadowView(textSegment: segment, applyOnAll: viewModel.applyShadowOnAllTextSegments)
                                case .surroundColor:
                                    // TransitionTabView(textSegment: $testTextSegment)
                                    TextSegmentWrappingView(textSegment: segment , applyOnAll: viewModel.applySurroundOnAllTextSegments)
                                case .delete:
                                    //TransitionTabView(textSegment: $testTextSegment)
                                    
                                    DeleteSegmentTabView(segmentType: .text) {
                                        withAnimation(.bouncy) {
                                            viewModel.deleteSelectedTextSegment(trackIndex: trackIndex, segmentIndex: segmentIndex)
                                            selectedTab = nil
                                        }
                                    } cancelAction: {
                                        selectedTab = nil
                                    }
                                    
                                case .edit:
                                    EditTextSegmentTabView(textSegment: segment)
                                    
                                    
                                case .none:
                                    VStack{}
                                    
                                }
                                
                                Rectangle()
                                    .fill(Color("31313A"))
                                .frame(height: 2)

                            }
                            .background(
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture(coordinateSpace: .named("tabSpace")) {_ in
                                        withAnimation {
                                            selectedTab = nil
                                        }
                                    }
                            )
                            
                        }
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack(alignment:.top,spacing:5){
                                ForEach(TextEditingTab.allCases, id: \.self) { tab in
                                    Button {
                                        if selectedTab == tab {
                                            withAnimation {
                                                selectedTab = nil
                                            }
                                            
                                        }else{
                                            withAnimation(.bouncy) {
                                                selectedTab = tab
                                            }
                                        }
                                    } label: {
                                        VStack{
                                            Image(tab.icon)
                                                .foregroundStyle(selectedTab == tab ?  Color("primary-color"):Color("9191A8"))
                                            Spacer()
                                            Text(tab.rawValue)
                                                .foregroundStyle(selectedTab == tab ? Color("primary-color"):Color("6C6C7B"))
                                                .font(.medium10)
                                        }
                                        
                                    }
                                    .frame(width: 60, height: 50)
                                    
                                }
                            }
                            
                        }
                        .frame(height: 60)
                        .padding(.vertical,10)
                        .padding(.leading,10)
                        .background(Color("27272F"))
                        
                    }
                }
                
                
            }
            
            
            
            
        }
        .background(Color.clear)
        
    }
        
    
    
    
    
    
}



#Preview {
    TextSegmentsEditingBar(viewModel: MontageVM())
        .background(Color("main-background"))
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
    
    
}



