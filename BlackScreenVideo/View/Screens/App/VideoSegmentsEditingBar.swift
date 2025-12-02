//
//  TextEditingTab.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 18/11/2025.
//


import SwiftUI
enum VideoEditingTab : LocalizedStringKey , CaseIterable{
    case split = "Split"
    case delete = "Delete"
    case volume = "Volume"
    case exchange = "Exchange"

    var icon : String {
        switch self {
        case .split:
            return "split-icon"
        case .volume:
            return "volume-icon"
        case .exchange:
            return "exchange-icon"
        case .delete:
            return "trash-icon"

        }
    }
}

struct VideoSegmentsEditingBar: View {
    @Environment(\.layoutDirection) var layoutDirection
    @State var selectedTab : VideoEditingTab? = nil
    @ObservedObject var viewModel : MontageVM
    //    @State var testAudioSegment : AudioSegment? = AudioSegment(name: "test", fileURL: .applicationDirectory, audioDuration: 200, audioStartTime: 0, startTime: 0, duration: 200)
    
    @State var showVideoPicker : Bool = false
    
    var body: some View {
        
        VStack(spacing:0){
            
            if let segmentId = viewModel.videoSegmentSelectedID {
                
                
                if let segmentIndex =  viewModel.videoTrack.firstIndex(where: { $0.id == segmentId }) {
                    
                    let segmentBinding = Binding<VideoSegment?>(
                        get: { viewModel.videoTrack[segmentIndex] },
                        set: { newValue in
                            if let newValue {
                                viewModel.videoTrack[segmentIndex] = newValue
                            }
                        }
                    )
                    if selectedTab != nil {
                        
                        VStack(spacing : 0){
                            Spacer()
                            
                            Rectangle()
                                .fill(Color("31313A"))
                                .frame(height: 2)
                            
                            switch selectedTab {
                            case .split:
                                EmptyView()
                            case .volume:
                                MediaVolumeTabView(audioSegment: .constant(nil),videoSegment: segmentBinding)
                                
                            case .exchange:
                                EmptyView()
                            case .delete:
                                DeleteSegmentTabView(segmentType: .media) {
                                    viewModel.deleteSelectedVideoSegment(segmentIndex: segmentIndex)
                                    selectedTab = nil
                                } cancelAction: {
                                    withAnimation {
                                        selectedTab = nil
                                    }
                                }
                                
                                
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
                            ForEach(VideoEditingTab.allCases, id: \.self) { tab in
                                Button {
                                    if tab == .split {
                                        viewModel.splitVideoSegment(at: viewModel.currentTime)
                                    }else if tab == .exchange{
                                        showVideoPicker = true
                                    }
                                    else{
                                        if selectedTab == tab {
                                            withAnimation {
                                                selectedTab = nil
                                            }
                                        }else{
                                            withAnimation(.bouncy) {
                                                selectedTab = tab
                                            }
                                        }
                                    }
                                    
                                } label: {
                                    VStack{
                                        Image(tab.icon)
                                            .foregroundStyle(selectedTab == tab ?  Color("4A4AFF"):Color("9191A8"))
                                        Spacer()
                                        Text(tab.rawValue)
                                            .foregroundStyle(selectedTab == tab ? Color("4A4AFF"):Color("6C6C7B"))
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
        .sheet(isPresented: $showVideoPicker) {
            VideoPickerView{ video in
                
                showVideoPicker = false
                viewModel.exchangeSelectedVideoSegment(with: video)
            }
            .presentationCornerRadius(20)
            .presentationDetents([.height(200)])
            .environment(\.layoutDirection,layoutDirection)
        }
        
        
    }
    
    
    
    
}
