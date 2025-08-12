//
//  SegmentColorTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
struct TextSegmentColorTabView: View {
    
    @Binding var textSegment : TextSegment
    @State var selectedColor : UIColor? = nil
    let type : SegmentColorType
    let applyOnAll : (TextSegmentColor,SegmentColorType) -> Void
    
    @State var opacity : Double = 100
    var body: some View {
        VStack{
            VStack{
                HStack{
                    Text(type.title)
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                    
                    
                    Spacer()
                    ApplyOnAllButton{
                        switch type {
                        case .text:
                            applyOnAll(textSegment.textColor ,.text)
                        case .background:
                            if let backgroundColor = textSegment.backgroundColor{
                                applyOnAll(backgroundColor,.background)
                            }
                            
                        }
                    }
                    
                    
                }
                .padding(.vertical,20)
                
                AppColorPickerView(selectedColor: $selectedColor)
                
                HStack{
                    Text("Opacity")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                    Slider(value: $opacity, in: 0...100)
                        .accentColor(Color("4A4AFF"))
                    Text(String(Int(opacity)))
                        .foregroundStyle(.white)
                        .font(.medium14)
                        .frame(width: 40)
                    
                    
                    
                    
                }
                .padding(.bottom,20)
                
                if type == .background{
                    ResetButton(action: {
                        clearBackground()
                    })
                    .padding(.bottom,20)

                }
            }
            .padding(.horizontal ,20)

            
        }
        .background(Color("27272F"))

        .onChange(of: opacity) { oldValue , newValue in
            changeOpacity(newValue)
        }
        .onChange(of: selectedColor) { oldValue , newValue in
            if let color = newValue{
                selectColor(color)
            }
        }
        .onAppear{
            selectedColor = detectSelectedColor()
        }
        
        
    }
    
    func selectColor(_ color: UIColor){
        switch type {
        case .text:
            self.textSegment.textColor.color = color
        case .background:
            if self.textSegment.backgroundColor == nil{
                self.textSegment.backgroundColor = .init(color: color, opacity: 100)

            }else{
                self.textSegment.backgroundColor?.color = color
            }
            
        }
    }
    func detectSelectedColor() -> UIColor? {
        switch type {
        case .text:
            return self.textSegment.textColor.color
        case .background:
           return self.textSegment.backgroundColor?.color
            
        }
    }
    
    func changeOpacity(_ opacity: Double){
        switch type {
        case .text:
            self.textSegment.textColor.opacity = opacity
        case .background:
            self.textSegment.backgroundColor?.opacity = opacity
            
        }
    }
    
    func clearBackground(){
        self.textSegment.backgroundColor = nil
        self.selectedColor = nil
    }
    
}
