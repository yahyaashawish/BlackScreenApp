//
//  VideoPreviewView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 31/05/2025.
//


import SwiftUI
struct AddNewTextSegmentView: View {
    @Environment(\.dismiss) var dismiss
    @State var text: String = ""
    @State var isFocused: Bool? = false
    var placeholder: LocalizedStringKey = "Enter text here"
    let onAdd: (String) -> Void
    var body: some View {
        ZStack{
            Color("27272F").ignoresSafeArea()
            
            HStack{
                Spacer()
                AppTextField(placeholder: placeholder, text: $text,radius: 10,bgColor: Color("474755"),placeholderColor: .white,height: 40,isFocused: $isFocused)
                    .onAppear{
                        isFocused = true
                    }
                Button {
                    if !text.isEmpty {
                        onAdd(text)
                        dismiss()
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("4A4AFF"))
                        .frame(width: 60, height: 40)
                        .overlay {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                                .font(.bold20)
                        }
                }
                Spacer()

            }
            .padding(.horizontal,20)
        }

        
    }
}

#Preview {
    AddNewTextSegmentView(onAdd: { text in
        
    })
        .background(Color("main-background"))

        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .leftToRight )
    
    
}
