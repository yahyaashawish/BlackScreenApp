import SwiftUI
import GoogleMobileAds

struct MontageView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.dismiss) var dismiss

    @StateObject private var adViewModel = BannerAdVM()
    var interstitialAdsManager = InterstitialAd.shared
    @StateObject var montageVM: MontageVM
    @State var showExitSheet : Bool = false
    @State var showAddNewTextSheet : Bool = false
    @State var showMusicPickerView : Bool = false
    @State var showExportingView : Bool = false
    let videoSize : VideoSize
    let initialSong : LocalSong
    
    init(videoSize : VideoSize , initialSong : LocalSong){
        self.videoSize = videoSize
        self.initialSong = initialSong
        _montageVM = .init(wrappedValue: .init(initialSong: initialSong, videoSize: videoSize))
        
        
    }
    var body: some View {
        GeometryReader{ geometry in
            
            ZStack(alignment:.bottom){
                AppBackground()
                VStack{
                    VStack(){
                        HStack{
                            
                            Button{
                                showExitSheet = true
                            }label:{
                                Image("close-rect")
                            }
                            
                            HStack(spacing:0){
                                Button{
                                    montageVM.undo()
                                }label:{
                                    Image("undoicon")
                                        .foregroundStyle(montageVM.undoStackIsEmpty ? Color("474755") : Color("9191A8"))

                                        .flipsForRightToLeftLayoutDirection(true)
                                }
                                .disabled(montageVM.undoStackIsEmpty)

                                .frame(width:40,height:40)
                                Button{
                                    montageVM.redo()
                                }label:{
                                    Image("redoicon")
                                        .foregroundStyle(montageVM.redoStackIsEmpty ? Color("474755") : Color("9191A8"))
                                        .flipsForRightToLeftLayoutDirection(true)
                                }
                                .disabled(montageVM.redoStackIsEmpty)

                                .frame(width:40,height:40)

                            }
                            .padding(.horizontal,30)
                            Spacer()
                            
                            Button{
                                showExportingView = true
                            }label:{
                                HStack{
                                    Text("Export and Save")
                                        .font(.hevay16)
                                        .foregroundColor(.black)
                                        .padding(.horizontal,20)
                                        .padding(.vertical,5)
                                }
                                .background(Color("34CC99"))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                        .padding(.bottom,20)
                        
                        VideoPreviewView(viewModel: montageVM)
                        
                        
                    }
                    .padding(.horizontal,20)
                    
                        VStack{
                            HStack (alignment: .top){
                                HStack(spacing:20){
                                    Button{
                                        if montageVM.isPreviewPlaying {
                                            montageVM.pausePreviewPlayback()
                                        } else {
                                            montageVM.startPreviewPlayback()
                                        }
                                    }label:{
                                        Image(systemName: montageVM.isPreviewPlaying ? "pause.fill" : "play.fill")
                                            .resizable()
                                            .frame(width: 15,height: 15)
                                            .foregroundStyle(.white)
                                    }
                                    Button{
                                        montageVM.stopAndResetPreviewPlayback()
                                    }label:{
                                        Image(systemName: "stop.fill")
                                            .resizable()
                                            .frame(width: 15,height: 15)
                                            .foregroundStyle(.white)
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.magnifyingglass")
                                    .foregroundStyle(Color("9191A8"))
                                CustomSlider(value: $montageVM.rawTimeScale,range: 1...PropertiesConstants.MaximumScaleTime,thumbSize: 15)
                                    .frame(width: 100)
                                Image(systemName: "minus.magnifyingglass")
                                    .foregroundStyle(Color("9191A8"))
                                
                                
                            }
                            .padding(.horizontal,20)
                            .padding(.top,20)
                            HStack(alignment: .top){
                                
                                VStack{
                                    
                                    Button {
                                        showAddNewTextSheet = true
                                    } label: {
                                        Image("add-text")
                                    }
                                    
                                    Button {
                                        showMusicPickerView = true
                                    } label: {
                                        Image("add-audio")
                                    }
                                    
                                }
                                .background(Color("1B1B22"))
                                .clipShape(SingleCornerRoundedRectangle(cornerRadius: 20, corners: .topRight))
                                .padding(.top,25)
                                
                                
                                
                                VStack(alignment: .leading){
                                    
                                    TimelineView(viewModel: montageVM)
                                    
                                    
                                }
                                
                            }

                        }
                        
                            

                    
                    
                    .environment(\.layoutDirection,  .leftToRight )


                }
                GeometryReader { adGeo in
                    let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(adGeo.size.width)
                    BannerView(adSize: adSize,isCollapsed: false, isTop: false)
                }
                .frame(height: 50)
                SegmentsEditingBar(viewModel: montageVM)

                

            }
            .frame(height: geometry.size.height)
            
        }
        .onChange(of: montageVM.textTracks, { oldValue, newValue in
            if montageVM.outputURL != nil {
                montageVM.outputURL = nil
            }
        })
        .onChange(of: montageVM.audioSegments, { oldValue, newValue in
            if montageVM.outputURL != nil {
                montageVM.outputURL = nil
            }
        })
        
        .sheet(isPresented: $showAddNewTextSheet, content: {
            AddNewTextSegmentView { text in
                montageVM.addTextSegment(with: text)
            }
            .presentationCornerRadius(20)
            .presentationDetents([.height(120)])
            .presentationBackground(.clear)
            
        })
        .sheet(isPresented: $showMusicPickerView) {
            
            AudioPickerView{ song in
                showMusicPickerView = false
                montageVM.addAudioSegment(song: song)
                
            }
            .presentationCornerRadius(20)
            
        }
        .sheet(isPresented: $showExitSheet) {
            
            ExitMontageSheet(){
                dismiss()
            }
            .environment(\.layoutDirection, LanguageSetting.shared.isRightToLeft ? .rightToLeft : .leftToRight )
            .presentationCornerRadius(20)
            .presentationDetents([.height(200)])
            
        }
        .fullScreenCover(isPresented: $showExportingView, content: {
            ExportedVideoView(viewModel : montageVM)
        })
        .navigationBarBackButtonHidden(true)
    }
    
    
    
    
    
    
    
    
}









#Preview {
    NavigationStack{
        MontageView(videoSize: .portrait9_16, initialSong: LocalSong(name: "test", duration: 20, url: URL.homeDirectory))
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}



