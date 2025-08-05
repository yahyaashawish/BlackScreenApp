//
//  AppSongsLibraryView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 17/05/2025.
//

import SwiftUI

struct AppSongsLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var songsLibraryVM = AppSongsLibraryVM()
    @State var isSearchFieldFocused: Bool? = false
    let onSelectSong: (LocalSong) -> Void
    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .top){
                AppBackground()
                VStack{
                    TitlebarWithBackButton(title: "App Library")
                        .padding(.horizontal, 20)

                    AppTextField(placeholder: "...Search words", text: $songsLibraryVM.searchSongName, icon: "search-icon", height: 36, bgColor: Color("27272F"), isFocused: $isSearchFieldFocused) {
                        
                    }
                    .padding(.horizontal, 20)
                    SongsFoldersView(foldersVM: songsLibraryVM)
                        .padding(.leading,20)
                    FolderSongsView(songsVM: songsLibraryVM,onSelectSong: onSelectSong)
                        .padding(.horizontal, 20)
                    
                    
                    
                }
                .onChange(of: songsLibraryVM.searchSongName) { oldValue, newValue in
                    if !newValue.isEmpty {
                        songsLibraryVM.selectedFolder = nil
                        songsLibraryVM.loadSongsWithName(name: newValue,isForNewNameSearch: true)
                    }
                }
            }
            

        }
       
    }
}

#Preview {
    AppSongsLibraryView(){ song in
        
    }
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
}

struct TitlebarWithBackButton: View {
    let title: LocalizedStringKey
    var body: some View {
        HStack{
            AppBackButton()
            Text(title)
                .font(.medium24)
                .foregroundStyle(Color("C3C3D8"))
            Spacer()
            
        }
    }
}
