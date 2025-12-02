//
//  AudioVolumeTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
struct MediaVolumeTabView: View {
    @Binding var audioSegment : AudioSegment?
    @Binding var videoSegment : VideoSegment?
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
                    .accentColor(Color("4A4AFF"))
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
            if audioSegment != nil{
                self.volume = audioSegment!.volume
            }
            
            if videoSegment != nil{
                self.volume = videoSegment!.volume
            }
        }
        
    }
    func changeVolume(_ volume: Float){
        if audioSegment != nil{
            self.audioSegment!.volume = volume
        }
        
        if videoSegment != nil{
            self.videoSegment!.volume = volume
        }
    }
}
