//
//  TextSegmentShadowView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 20/06/2025.
//

import SwiftUI
struct TextSegmentWrappingView: View {
    @Binding var textSegment : TextSegment
    let applyOnAll : (TextSegmentWrapping) -> Void
    @State var selectedColor : UIColor? = nil
    @State var width : Double = 0
    var body: some View {
        VStack{
            VStack{
                
                HStack{
                    Text("Text Wrapping")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                    
                    Spacer()
                    ApplyOnAllButton{
                        if let textWrapping = textSegment.textWrapping {
                            applyOnAll(textWrapping)
                        }
                    }
                    
                }
                .padding(.top,20)
                
                HStack(alignment : .center){
                    Text("Color")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 70,height: 60,alignment: .topLeading)
                    
                    AppColorPickerView(selectedColor: $selectedColor)
                    
                    
                    
                }

                HStack{
                    Text("Thickness")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 80,alignment: .leading)
                    
                    Slider(value: $width, in: 0...100)
                        .accentColor(Color("4A4AFF"))
                    HStack(spacing:0){
                        Text(String(Int(width)))
                            .foregroundStyle(.white)
                            .font(.medium14)
                            .frame(width: 30)
                        
                    }
                    
                }
                
                ResetButton(action: {
                    clearSurround()
                })
                .padding(.bottom,20)
            }
            .padding(.horizontal,20)
            
            
            
        }
        .background(Color("27272F"))


        .onChange(of: width) { oldValue , newValue in
            changeWidth(newValue)
        }
        .onChange(of: selectedColor, { oldValue, newValue in
            if let color = newValue{
                changeColor(color)
            }
        })
        .onAppear{
            if let textWrapper = textSegment.textWrapping{
                width = textWrapper.thickness
            }
            selectedColor = self.textSegment.textWrapping?.color

        }
    }

    func changeWidth(_ value: Double){
        if textSegment.textWrapping == nil{
            textSegment.textWrapping = .init(color: .white, thickness: value)
        }else {
            textSegment.textWrapping?.thickness = value
        }

    }
    func changeColor(_ color: UIColor){
        if textSegment.textWrapping == nil{
            textSegment.textWrapping = .init(color: color, thickness: 100)
            self.width = 100
        }else {
            textSegment.textWrapping?.color = color
        }
    }

    func clearSurround(){
        textSegment.textWrapping = nil
        selectedColor = nil
        width = 0
    }
    
}
#Preview {
    TextSegmentWrappingView(textSegment: .constant(TextSegment(content: "test", startTime: 30, duration: 55)),applyOnAll: { shadow in
        
    })
        .background(Color("27272F"))
}

