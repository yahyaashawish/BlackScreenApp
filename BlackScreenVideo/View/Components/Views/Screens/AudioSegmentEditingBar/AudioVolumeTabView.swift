//
//  AudioVolumeTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
struct AudioVolumeTabView: View {
    @Binding var audioSegment : AudioSegment
    @State var volume : Float = 100
    
    var body: some View {
        VStack{
            HStack{
                Text("ِAudio Volume")
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                
                Spacer()
                
                
            }
            .padding(.horizontal,20)
            .padding(.top,20)

            HStack{
                
                Slider(value: $volume, in: 0...100)
                    .accentColor(Color("primary-color"))
                Text(String(Int(volume)))
                    .foregroundStyle(.white)
                    .font(.medium14)
                    .frame(width: 40)
                
                
                
            }
            .padding(.horizontal ,20)
            .padding(.bottom,20)
            
            
        }
        .background(Color("27272F"))

        .onChange(of: volume) { oldValue , newValue in
            changeVolume(newValue)
        }
        .onAppear{
            self.volume = audioSegment.volume
        }
        
    }
    func changeVolume(_ volume: Float){
        self.audioSegment.volume = volume
    }
}
