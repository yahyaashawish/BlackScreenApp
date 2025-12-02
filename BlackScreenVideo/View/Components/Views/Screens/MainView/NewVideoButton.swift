import SwiftUI
struct NewVideoButton: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.dismiss) var dismiss
    let isForLibraryView : Bool
    @State var showVideoSizePicker : Bool = false
    @State var selectedVideoSize : VideoSize?
    @State var selectedSong : LocalSong?
    @State var showMusicPickerView : Bool = false
    @State var showMontageView : Bool = false
    var body: some View {
        Button{
            showVideoSizePicker = true
        }label: {
            if isForLibraryView {
                HStack(spacing:20){
                    Text("Make Video now")
                        .font(.bold18)
                        .foregroundStyle(.white)
                        .padding(.leading,5)
                    Image("arrow")
                        .rotationEffect(.degrees(layoutDirection == .leftToRight ? 0 : 180))
                        .padding(.horizontal,5)
                }
                .padding(10)
                .background(Color("secondry-color"))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }else {
                HStack{
                    VStack(alignment:.leading,spacing: 5){
                        Text("New Video 🚀")
                            .font(.bold18)
                            .foregroundStyle(.white)
                        
                        Text("Choose the music and start making the video")
                            .font(.regular10)
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom,25)
                    
                    Spacer()
                    Image("new-video-icon")
                    
                    
                }
                .padding(.horizontal,25)
                .padding(.top,25)
                .frame(height: 114)
                .background(Color("4A4AFF"))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            
        }
        .onChange(of: showMontageView, { oldValue, newValue in
            if newValue{
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    InterstitialAd.shared.loadAdAndShow()
                }
            }
        })
        
        .navigationDestination(isPresented: $showMontageView, destination: {
            if let videoSize = selectedVideoSize {
                MontageView(videoSize: videoSize, initialSong: selectedSong)
            }
        })
        .sheet(isPresented: $showVideoSizePicker) {
            ChooseVideoSizeSheet(sizeSelection: $selectedVideoSize)
                .presentationCornerRadius(20)
                .presentationDetents([.height(550)])
                .presentationBackground(.clear)
                .environment(\.layoutDirection,  layoutDirection )
        }
        
        .sheet(isPresented: $showMusicPickerView) {
            
            AudioPickerView(isForNewProject: true){ song in
                showMusicPickerView = false

                selectedSong = song
                showMontageView = true
                
            }
                .presentationCornerRadius(20)
                .presentationDetents([.height(200)])
                .environment(\.layoutDirection,  layoutDirection )

        }
        .onChange(of: selectedVideoSize) { oldValue, newValue in
            if newValue != nil {
                showMusicPickerView = true
            }
        }
        
        
        
        
        
    }

    
    
}









#Preview {
    NavigationStack{
        NewVideoButton(isForLibraryView: false)
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




