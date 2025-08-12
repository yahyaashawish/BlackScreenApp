//
//  TextSegmentShadowView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 20/06/2025.
//

import SwiftUI
struct TextSegmentShadowView: View {
    @Binding var textSegment : TextSegment
    let applyOnAll : (TextSegmentShadow) -> Void
    @State var selectedColor : UIColor? = nil

    @State var opacity : Double = 100
    @State var radius : Double = 50
    @State var offset : Double = 20
    
    var body: some View {
        VStack{
            VStack{
                HStack{
                    Text("Shadow")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                    
                    Spacer()
                    ApplyOnAllButton{
                        if let shadow = textSegment.shadow {
                            applyOnAll(shadow)
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
                
                HStack(alignment : .center){
                    Text("Angle")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 70,alignment: .leading)
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(alignment:.top,spacing:5){
                            
                            
                            
                            ForEach(ShadowAngle.allCases, id: \.self) { angle in
                                VStack{
                                    Button {
                                        changeAngle(angle)
                                    } label: {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(textSegment.shadow?.angle == angle ? Color("4A4AFF") : Color("474755"))
                                            .frame(width: 24, height: 24)
                                            .overlay(alignment: angle.alignment) {
                                                Circle()
                                                    .fill(.white)
                                                    .frame(width: 5, height: 5)
                                                    .padding(5)
                                            }
                                    }
                                    
                                    if textSegment.shadow?.angle == angle{
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(.white)
                                            .frame(width: 7, height: 3)
                                    }
                                }
                                
                                
                            }
                        }
                        
                        
                    }
                    .environment(\.layoutDirection,  .leftToRight )

                    
                    
                }
                
                
                HStack{
                    Text("Opacity")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 70,alignment: .leading)
                    Slider(value: $opacity, in: 0...100)
                        .accentColor(Color("4A4AFF"))
                    HStack(spacing:0){
                        Text(String(Int(opacity)))
                            .foregroundStyle(.white)
                            .font(.medium14)
                            .frame(width: 30)
                        
                    }
                    
                }
                
                HStack{
                    Text("Radius")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 70,alignment: .leading)
                    Slider(value: $radius, in: 0...100)
                        .accentColor(Color("4A4AFF"))
                    HStack(spacing:0){
                        Text(String(Int(radius)))
                            .foregroundStyle(.white)
                            .font(.medium14)
                            .frame(width: 30)
                        
                    }
                    
                }
                
                HStack{
                    Text("Offset")
                        .foregroundStyle(Color("9191A8"))
                        .font(.medium16)
                        .frame(width: 70,alignment: .leading)
                    
                    Slider(value: $offset, in: 0...100)
                        .accentColor(Color("4A4AFF"))
                    HStack(spacing:0){
                        Text(String(Int(offset)))
                            .foregroundStyle(.white)
                            .font(.medium14)
                            .frame(width: 30)
                        
                    }
                    
                }
                
                ResetButton(action: {
                    clearShadow()
                })
                .padding(.bottom,20)
            }
            .padding(.horizontal,20)
            
            
            
        }
        .background(Color("27272F"))
        .onChange(of: selectedColor) { oldValue, newValue in
            if let color = newValue{
                changeColor(color)
            }
        }
        .onChange(of: opacity) { oldValue , newValue in
            changeOpacity(newValue)
        }
        .onChange(of: offset) { oldValue , newValue in
            changeOffset(newValue)

        }
        .onChange(of: radius) { oldValue , newValue in
            changeRadius(newValue)
            
        }
        .onAppear{
            if let shadow = textSegment.shadow {
                opacity = shadow.opacity
                radius = shadow.radius
                offset = shadow.offset
            }
            selectedColor = self.textSegment.shadow?.color

            
        }
    }
    func changeOpacity(_ value: Double){
        if textSegment.shadow == nil{
            textSegment.shadow = .init(color: .white, angle: .bottom, opacity: value ,radius: 50, offset: 20)

        }else {
            textSegment.shadow?.opacity = value
        }
    }
    func changeRadius(_ value: Double){
        if textSegment.shadow == nil{
            textSegment.shadow = .init(color: .white, angle: .bottom, opacity: 100,radius: value, offset: 20)
        }else {
            textSegment.shadow?.radius = value

        }
        
    }
    func changeOffset(_ value: Double){
        if textSegment.shadow == nil{
            textSegment.shadow = .init(color: .white, angle: .bottom, opacity: 100,radius: 50, offset: value)
        }else {
            textSegment.shadow?.offset = value

        }

    }
    func changeColor(_ color: UIColor){
        if textSegment.shadow == nil{
            textSegment.shadow = .init(color: color, angle: .bottom, opacity: 100,radius: 50, offset: 20)
        }else {
            textSegment.shadow?.color = color
        }
    }
    
    func changeAngle(_ angle: ShadowAngle){
        if textSegment.shadow == nil{
            textSegment.shadow = .init(color: .white, angle: angle, opacity: 100,radius: 50, offset: 0)
        }else {
            textSegment.shadow?.angle = angle
        }
    }
    
    func clearShadow(){
        textSegment.shadow = nil
        selectedColor = nil
        opacity = 100
        radius = 50
        offset = 20
    }

}
#Preview {
    TextSegmentShadowView(textSegment: .constant(TextSegment(content: "test", startTime: 30, duration: 55)),applyOnAll: { shadow in
        
    })
        .background(Color("27272F"))
}

struct ApplyOnAllButton: View {
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            HStack{
                ZStack{
                    Image("check-icon-1")
                    Image("check-icon-2")
                        .offset(x:5)
                }
                
                VStack(spacing: 0){
                    
                    Text("Apply on all")
                    
                        .foregroundStyle(.white)
                        .font(.medium14)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width :80,height: 1)
                        .foregroundStyle(.white)
                }
                
                
                
                
            }
        }
    }
}
