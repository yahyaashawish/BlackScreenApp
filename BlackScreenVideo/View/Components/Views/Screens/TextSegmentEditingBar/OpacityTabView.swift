//
//  OpacityTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
struct OpacityTabView: View {
    @Binding var textSegment : TextSegment
    @State var opacity : Double = 100
    
    var body: some View {
        VStack{
            HStack{
                Text("Opacity")
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                
                Spacer()
                
                
            }
            .padding(.top,20)
            .padding(.horizontal,20)
            
            HStack{
                
                Slider(value: $opacity, in: 0...100)
                    .accentColor(Color("primary-color"))
                Text(String(Int(opacity)))
                    .foregroundStyle(.white)
                    .font(.medium14)
                    .frame(width: 40)
                
                
                
            }
            .padding(.horizontal ,20)
            .padding(.bottom,20)
            
            
        }
        .background(Color("27272F"))

        .onChange(of: opacity) { oldValue , newValue in
            changeOpacity(newValue)
        }
        .onAppear{
            opacity = self.textSegment.opacity
        }
    }
    func changeOpacity(_ opacity: Double){
        self.textSegment.opacity = opacity 
    }
}
