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
                
               
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.localFonts, id: \.id) { font in
                            
                            Button {
                                selectFont(font)
                            } label: {
                                HStack{
                                    Text(font.fontName ?? "name not found")
                                        .foregroundStyle( textSegment.font?.id == font.id  ? .white : Color("9191A8"))
                                        .font(Font.custom(font.fontName ?? "not_found", size: 14))
                                    
                                    
                                    
                                }
                                .frame(width: 98,height: 36)
                                .background(textSegment.font?.id == font.id ? Color("primary-color") : Color("474755"))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                                .onAppear{
                                    if font.id == viewModel.localFonts.last?.id {
                                        viewModel.fetchFontsForNextPage()
                                    }
                                    
                                }
                        }
                        
                        
                        
                    }
                    .padding(.top,20)
                }
                .onAppear {
                    viewModel.fetchFontsForNextPage()
                    
                }
                if viewModel.isFetching {
                        Spinner()
                }else if viewModel.localFonts.isEmpty {
                    VStack(spacing: 10){
                        Text("There is no font available")
                            .font(Font.medium10)
                            .foregroundStyle(Color("9191A8"))
                        
                        Button("Try Again!") {
                            viewModel.fetchFontsForNextPage()
                        }
                        .font(Font.medium12)
                        .foregroundStyle(.cyan)
                    }
                }
                
                
                
            }
            .padding(.horizontal,20)
            .padding(.vertical,20)

            
            
        }
        .background(Color("27272F"))
        .frame(height:250)
       
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

