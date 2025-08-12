//
//  VideoPreviewView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 31/05/2025.
//



import SwiftUI
enum AudioEditingTab : LocalizedStringKey , CaseIterable{
    case split = "Split"
    case volume = "Volume"
    case faders = "Fade"
    case cutter = "Cutter"
    case exchange = "Exchange"
    case delete = "Delete"
    
    var icon : String {
        switch self {
        case .split:
            return "split-icon"
        case .volume:
            return "volume-icon"
        case .faders:
            return "faders-icon"
        case .cutter:
            return "cut-icon"
        case .exchange:
            return "exchange-icon"
        case .delete:
            return "trash-icon"
            
        }
    }
}
struct AudioSegmentsEditingBar: View {
    @Environment(\.layoutDirection) var layoutDirection
    @State var selectedTab : AudioEditingTab? = nil
    @ObservedObject var viewModel : MontageVM
    //    @State var testAudioSegment : AudioSegment? = AudioSegment(name: "test", fileURL: .applicationDirectory, audioDuration: 200, audioStartTime: 0, startTime: 0, duration: 200)
    
    @State var showMusicPicker : Bool = false
    
    var body: some View {
        
        VStack(spacing:0){
            
            if let segmentId = viewModel.audioSegmentSelectedID {
                
                
                if let segmentIndex =  viewModel.audioSegments.firstIndex(where: { $0.id == segmentId }) {
                    
                    let segment = $viewModel.audioSegments[segmentIndex]
                    
                    
                    
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
                                AudioVolumeTabView(audioSegment: segment)
                                
                            case .faders:
                                AudioFadersTabView(audioSegment: segment)
                                
                            case .cutter:
                                AudioCutterTabView(segment: segment)
                            case .exchange:
                                EmptyView()
                            case .delete:
                                DeleteSegmentTabView(segmentType: .audio) {
                                    viewModel.deleteSelectedAudioSegment(segmentIndex: segmentIndex)
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
                                ForEach(AudioEditingTab.allCases, id: \.self) { tab in
                                    Button {
                                        if tab == .split {
                                            viewModel.splitAudioSegment(at: viewModel.currentTime)
                                        }else if tab == .exchange{
                                            showMusicPicker = true
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
        .sheet(isPresented: $showMusicPicker) {
            
            AudioPickerView{ song in
                
                showMusicPicker = false
                viewModel.exchangeSelectedSegment(with: song)
                
            }
            .presentationCornerRadius(20)
            .presentationDetents([.height(200)])
            
        }
        
        
    }
    
    
    
    
}
#Preview {
    AudioSegmentsEditingBar(viewModel: MontageVM())
        .background(Color("main-background"))
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .leftToRight )
    
    
}



