import SwiftUI

struct VideoPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.layoutDirection) var layoutDirection

    let onSelectVideo: (LocalVideo) -> Void
    @State var showAppLibrary : Bool = false
    @State var showGalleryPicker : Bool = false
    var body: some View {
        GeometryReader{ geometry in
            VStack{
                HStack{
                    Text("Choose video")
                        .font(.medium18)
                        .foregroundStyle(Color("C3C3D8"))
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
            .padding(20)

            
        }
        .background(Color("1B1B22"))
        
        .navigationBarBackButtonHidden(true)

        
        .sheet(isPresented: $showGalleryPicker) {
            GalleryVideoPicker(onPicked: onSelectVideo)
        }
        .sheet(isPresented: $showAppLibrary) {
            AppLibraryVideosPickerView(onSelectVideo: onSelectVideo)
                .environment(\.layoutDirection, layoutDirection)

        }

    }
    
    
    
    
    
    
    
    
}









#Preview {
    VideoPickerView(){ video in
        
    }
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




