//
//  TextSegmentShadowView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 20/06/2025.
//

import SwiftUI
import SwiftData


struct TextSegmentFontsView: View {

    @Binding var textSegment : TextSegment
    let applyOnAll : (LocalFont) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    @StateObject var viewModel : FontViewModel = FontViewModel()
    
    
    
    var body: some View {
        VStack{
            VStack(alignment:.center){
                
                HStack{
                    Text("Font Type")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                    
                    Spacer()
                    ApplyOnAllButton{
                        if let font = textSegment.font {
                            applyOnAll(font)
                        }
                    }
                    
                }
                
                HStack{
                    ForEach(FontType.allCases,id:\.self){ type in
                        Button{
                            viewModel.changeFontType(type)
                        }label: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedFontType == type ? Color("4A4AFF") : .clear)
                                .stroke(Color("27272F"), lineWidth: viewModel.selectedFontType == type ? 0 : 1)
                                .frame(height: 30)
                                .overlay {
                                    Text(type.title)
                                        .font(Font.hevay14)
                                        .foregroundStyle(viewModel.selectedFontType == type  ? Color("main-background") : Color("9191A8"))
                                }

                        }
                    }
                }
                
                VStack{
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.downLoadedFonts, id: \.id) { font in
                                    Button {
                                        selectFont(font)
                                    } label: {
                                        HStack{
                                            Text(font.fontName ?? "name not found")
                                                .foregroundStyle( textSegment.font?.id == font.id  ? .white : Color("9191A8"))
                                                .font(Font.custom(font.fontName ?? "not_found", size: 14))
                                            
                                            
                                            
                                        }
                                        .frame(width: 98,height: 36)
                                        .background(textSegment.font?.id == font.id ? Color("4A4AFF") : Color("474755"))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                    .onAppear{
                                        if font.id == viewModel.downLoadedFonts.last?.id {
                                            print("last font appears")
                                            viewModel.fetchFontsForNextPage(isNewType: false)
                                        }
                                        
                                    }
                                
                            }
                            
                            if viewModel.isFetching {
                                Spinner()
                            }
                            
                        }
                        .padding(.vertical,10)
                    }
                    if viewModel.localFonts.isEmpty && !viewModel.isFetching && viewModel.fetchedFontsCount == 0{
                        VStack(spacing: 10){
                            Text("There is no font available")
                                .font(Font.medium10)
                                .foregroundStyle(Color("9191A8"))
                            
                            Button("Try Again!") {
                                viewModel.fetchFontsForNextPage(isNewType: false)
                            }
                            .font(Font.medium12)
                            .foregroundStyle(.cyan)
                        }
                    }
                }
                
                
                .onAppear {
                    viewModel.fetchFontsForNextPage(isNewType: true)

                }
                
                
                
                
            }
            .padding(.horizontal,20)
            .padding(.vertical,20)

            
            
        }
        .background(Color("27272F"))
        .frame(height:300)
       
    }
    
    func selectFont(_ font : LocalFont){
        if textSegment.font?.id == font.id {
            self.textSegment.font = nil
        }else{
            self.textSegment.font = font

        }
    }

}
#Preview {
    TextSegmentFontsView(textSegment: .constant(TextSegment(content: "test", startTime: 30, duration: 55)),applyOnAll: { font in
        
    })
        .background(Color("27272F"))
}

