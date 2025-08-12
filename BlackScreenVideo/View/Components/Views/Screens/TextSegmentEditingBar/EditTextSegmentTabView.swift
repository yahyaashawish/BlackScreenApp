//
//  OpacityTabView 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 25/06/2025.
//


import SwiftUI
struct EditTextSegmentTabView: View {
    @Binding var textSegment : TextSegment
    @State var text: String = ""
    @State var isFocused: Bool? = false
    @State var fontSize : Double = 16

    var body: some View {
        VStack{
            VStack{
                HStack{
                    Text("Text")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                    
                    Spacer()
                    
                    
                }
                
                HStack{
                    AppTextField(placeholder: "Enter text here", text: $text,radius: 10,bgColor: Color("474755"),placeholderColor: .white,height: 40,isFocused: $isFocused)
                        .onAppear{
                            text = textSegment.content
                        }
                    Button {
                        if !text.isEmpty {
                            textSegment.content = text
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
                    
                }
                
                HStack{
                    Text("Text Alignment")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 150, alignment: .leading)
                    HStack{
                        ForEach(TextSegmentAlignment.allCases, id: \.self) { alignment in
                            Button {
                                selectAlignment(alignment)
                            } label: {
                                Image(systemName: alignment.icon)
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(textSegment.alignment == alignment ? Color("4A4AFF") : Color("9191A8"))
                            }

                            
                        }


                    }
                    .environment(\.layoutDirection,  .leftToRight )

                    Spacer()

                    
                    
                }
                .padding(.top,20)
                
                HStack{
                    Text("Font Size")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 150, alignment: .leading)
                    HStack{
                        Slider(value: $fontSize, in: 6...PropertiesConstants.MaximumFontSize)
                            .accentColor(Color("4A4AFF"))
                        Text(String(Int(fontSize)))
                            .foregroundStyle(.white)
                            .font(.medium14)
                            .frame(width: 40)
                        
                    }
                    
                    Spacer()
                    
                    
                    
                }
                .padding(.top,10)
                
                
            }
            .padding(20)

            
            
        }
        .background(Color("27272F"))
        .onChange(of: fontSize) { old, newValue in
            selectFontSize(newValue)
        }
        .onAppear{
            fontSize = textSegment.fontSize
        }
        
    }
    
    func selectAlignment(_ alignment: TextSegmentAlignment) {
        textSegment.alignment = alignment
    }
    
    func selectFontSize(_ fontSize: CGFloat) {
        textSegment.fontSize = fontSize
    }
   
}
#Preview {
    EditTextSegmentTabView(textSegment: .constant(TextSegment(content: "test", startTime: 30, duration: 55)))
    .background(Color("27272F"))
}
