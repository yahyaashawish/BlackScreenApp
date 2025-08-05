//
//  AudioFadersTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
struct AudioFadersTabView: View {
    @Binding var audioSegment : AudioSegment
    @State var fadeIn : Float = 0
    @State var fadeOut : Float = 0
    
    var body: some View {
        VStack{
            HStack{
                Text("Audio Fade In/Out")
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                
                Spacer()
                
                
            }
            .padding(.horizontal,20)
            .padding(.top,20)

            HStack{
                Text("Fade in")
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                    .frame(width: 100,alignment: .leading)
                Slider(value: $fadeIn, in: 0...PropertiesConstants.MaximumFadeInOut)
                    .accentColor(Color("primary-color"))
                HStack(spacing:0){
                    Text(String(format: "%.1f", fadeIn))
                        .foregroundStyle(.white)
                        .font(.medium14)
                        .frame(width: 30)
                    Text("S")
                        .foregroundStyle(.white)
                        .font(.medium14)
                }
                                
            }
            .padding(.horizontal ,20)

            HStack{
                Text("Fade out")
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                    .frame(width: 100,alignment: .leading)

                Slider(value: $fadeOut, in: 0...PropertiesConstants.MaximumFadeInOut)
                    .accentColor(Color("primary-color"))
                HStack(spacing:0){
                    Text(String(format: "%.1f", fadeOut))
                        .foregroundStyle(.white)
                        .font(.medium14)
                        .frame(width: 30)
                    Text("S")
                        .foregroundStyle(.white)
                        .font(.medium14)
                }
                
            }
            .padding(.horizontal ,20)
            .padding(.bottom,20)
            
            
        }
        .background(Color("27272F"))

        .onChange(of: fadeIn) { oldValue , newValue in
            changeFadeIn(newValue)
        }
        .onChange(of: fadeOut) { oldValue , newValue in
            changeFadeOut(newValue)
        }
        .onAppear{
            self.fadeIn = Float(self.audioSegment.fadeInDuration)
            self.fadeOut = Float(self.audioSegment.fadeOutDuration)
        }
    }
    func changeFadeIn(_ value: Float){
        self.audioSegment.fadeInDuration = TimeInterval(value)
    }
    
    func changeFadeOut(_ value: Float){
        self.audioSegment.fadeOutDuration = TimeInterval(value)
    }
}

#Preview {
    AudioFadersTabView(audioSegment: .constant(AudioSegment(name: "test", fileURL: .applicationDirectory, audioOriginalDuration: 300, timeLineStartTime: 0, timeLineDuration: 20)))
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
}
