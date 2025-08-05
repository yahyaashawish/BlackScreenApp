

import SwiftUI

struct SongsFoldersView: View {
    
    @ObservedObject var foldersVM : AppSongsLibraryVM
    var body: some View {
        ZStack{
            ScrollView(.horizontal){
                LazyHStack{
                    FolderView(title:"" ,localizedTitle : "My Downloads", isSelected: foldersVM.isMyDownloadsSelected) {
                        foldersVM.selectedFolder = nil
                        foldersVM.loadDownloadedSongs()
                    }
                    
                    ForEach(foldersVM.folders, id: \.id){  folder in
                        FolderView(title: folder.name, isSelected: foldersVM.selectedFolder?.id == folder.id) {
                            foldersVM.selectedFolder = folder
                            foldersVM.isMyDownloadsSelected = false
                            foldersVM.loadSongs(isForNewFolder: true)
                        }
                        
                       
                    }
                    
                    
                    
                }
                
                
                
                
            }
            .frame( height: 60)
            if foldersVM.isLoadingFolders {
                Spinner()
                
            }
//            if let error = foldersVM.errorMessage{
//                VStack(spacing: 10){
//                    Text(error)
//                        .font(Font.medium14)
//                        .foregroundStyle(.red)
//                    
//                    Button("Try Again!") {
//                        foldersVM.loadFolders()
//                    }
//                    .font(Font.medium18)
//                    .foregroundStyle(.cyan)
//                }
//            }else if foldersVM.folders.isEmpty && !foldersVM.isLoadingFolders {
//                Text("No folders Available")
//                    .font(Font.medium18)
//                    .foregroundStyle(.gray)
//            }
        }
        .onAppear{
            foldersVM.loadDownloadedSongs()

        }

    }
}


#Preview {
    SongsFoldersView(foldersVM: AppSongsLibraryVM())
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
    
}

struct FolderView: View {
    let title: String
    var localizedTitle : LocalizedStringKey? = nil
    let isSelected : Bool
    let action: () -> Void
    var body: some View {
        HStack{
            if let localizedTitle {
                Text(localizedTitle)
                    .font(Font.hevay14)
                    .foregroundStyle(isSelected ? Color("main-background") : Color("9191A8"))
            }else{
                Text(title)
                    .font(Font.hevay14)
                    .foregroundStyle(isSelected ? Color("main-background") : Color("9191A8"))
            }
            
            
        }
        .padding(.vertical,5)
        .padding(.horizontal,10)
        .background(isSelected ? Color("primary-color") : .clear)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("27272F"), lineWidth: isSelected ? 0 : 1)
        )
        
        .onTapGesture {
            action()
            
        }
    }
}
