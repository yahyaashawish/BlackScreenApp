import SwiftUI

struct AudioPickerView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var appPath = AppPath.shared
    var isForNewProject: Bool = false
    let onSelectSong: (LocalSong?) -> Void
    @StateObject var settingsVM : SettingsVM = SettingsVM()
    @State var showAppLibrary : Bool = false
    @State var showICloudPicker : Bool = false
    @State var showGalleryPicker : Bool = false
    var body: some View {
        GeometryReader{ geometry in
            VStack{
                HStack{
                    Text("Choose music")
                        .font(.medium18)
                        .foregroundStyle(Color("C3C3D8"))
                    if isForNewProject {
                        Button{
                            onSelectSong(nil)
                        }label: {
                            Text("Skip")
                                .font(Font.regular16)
                                .foregroundStyle(Color("01B5FF"))
                                .underline()
                        }
                        .padding(.horizontal,10)
                    }
                    
                    Spacer()
                    Button{
                        dismiss()
                    }label: {
                        Image("circle-close")
                    }
                }
                
                HStack(spacing:15){
                    
                   
                    Button{
                        showGalleryPicker = true
                    }label: {
                        VStack{
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("27272F"))
                                .frame(height: 72)
                                .overlay {
                                    Image("music-circle")
                                }
                            
                            Text("Gallery")
                                .font(.regular16)
                                .foregroundStyle(Color("A1A1B9"))
                        }
                    }
                    
                    
                    Button{
                        showICloudPicker = true
                    }label: {
                        VStack{
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("27272F"))
                                .frame(height: 72)
                                .overlay {
                                    Image("cloud-music")
                                }
                            
                            Text("iCloud")
                                .font(.regular16)
                                .foregroundStyle(Color("A1A1B9"))
                        }
                    }
                    
                    if settingsVM.showApplibrary{
                        
                        Button{
                            showAppLibrary = true
                            
                        }label: {
                            VStack{
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color("27272F"))
                                    .frame(height: 72)
                                    .overlay {
                                        Image("music-library")
                                    }
                                
                                Text("App Library")
                                    .font(.regular16)
                                    .foregroundStyle(Color("A1A1B9"))
                            }
                        }
                    }
                    
                    
                    
                }
                
               
                
                
            }
            .padding(20)

            
        }
        .background(Color("1B1B22"))

        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showAppLibrary) {
            AppSongsLibraryView(onSelectSong: onSelectSong)
                .environment(\.layoutDirection, LanguageSetting.shared.isRightToLeft ? .rightToLeft : .leftToRight )

        }
        .sheet(isPresented: $showICloudPicker) {
            ICloudAudioPicker(onPicked: onSelectSong)
        }
        .sheet(isPresented: $showGalleryPicker) {
            GalleryAudioPicker(onPicked: onSelectSong)
        }

    }
    
    
    
    
    
    
    
    
}









#Preview {
    AudioPickerView(){ song in
        
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




