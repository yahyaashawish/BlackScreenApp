//
//  AudioVolumeTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
import AVFoundation

struct AudioCutterTabView: View {
    @Binding var segment : AudioSegment
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    let waveformHeight: CGFloat = 54

//    @State var audioSegment : AudioSegment = AudioSegment(name: "test", fileURL: .applicationDirectory, audioOriginalDuration: 300, timeLineStartTime: 0, timeLineDuration: 20)
    
    @State private var leftDX: CGFloat = 0
    @State private var rightDX: CGFloat = 0
    @State private var dur0: TimeInterval = 0
    @State private var crop0: TimeInterval = 0
    let handleWidth: Double = 20
    var body: some View {
        VStack {
            VStack(spacing: 30){
                HStack{
                    // Title
                    Text("Audio Cutting")
                    
                        .font(.title3)
                        .foregroundStyle(.gray)
                    
                    Spacer()
                    // Play Button
                    Button(action: togglePlay) {
                        Circle()
                            .fill(Color("4A4AFF"))
                            .frame(width: 35, height: 34)
                            .overlay(
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                            )
                    }
                }
                
                // Waveform with trimming overlay
                GeometryReader { geo in
                    let pxPS = geo.size.width / segment.audioOriginalDuration


                    let liveCrop = max(0,
                                       segment.audioStartTime + Double(leftDX / pxPS )
                    )
                    
                    let maxCrop = segment.audioOriginalDuration - liveCrop
                    let liveDur = min(
                        max(0.2, segment.audioDuration - Double(leftDX / pxPS ) + Double(rightDX / pxPS )),
                        maxCrop
                    )
                    let width = (liveDur * pxPS)
                    let centerX = liveCrop * pxPS  + width / 2
                    let leftX = centerX - width / 2 + handleWidth
                    
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color("FFC72C").opacity(0.15))
                            .overlay(
                                ZStack(alignment: .leading){
                                    WaveformView(amplitudes: segment.amplitudes,width: max(0,geo.size.width),height: waveformHeight)
                                        .clipped()
                                    
                                }
                                
                                , alignment: .leading)
                        
                            .frame(height: waveformHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        
                        
                        
                        HStack(spacing:0){
                            SingleCornerRoundedRectangle(cornerRadius: 5, corners: [.topLeft,.bottomLeft])
                                .fill(Color("FFC72C"))
                                .frame(width: handleWidth, height: waveformHeight)
                                .overlay(
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black)
                                        .frame(width: 3 , height: 10)
                                    
                                )
                                .gesture(
                                    DragGesture(coordinateSpace: .global)
                                        .onChanged { g in
                                            if dur0 == 0 {
                                                dur0 = segment.audioDuration
                                                crop0 = segment.audioStartTime
                                            }
                                            let proposedLeftDX = g.location.x - g.startLocation.x
                                                leftDX = proposedLeftDX
                                        }
                                        .onEnded { _ in
                                            segment.audioStartTime = min(liveCrop, segment.audioOriginalDuration - 35)
                                            segment.audioDuration = max(35, min(liveDur, segment.audioOriginalDuration - segment.audioStartTime))

                                            leftDX = 0
                                            dur0 = 0
                                        }
                                )
                               


                            Rectangle()
                                .fill(.clear)
                                .frame(height: waveformHeight-2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color("FFC72C"), lineWidth: 2)
                                )
                                .overlay {
                                    Text(formatSecondsToMinutes(liveDur))
                                        .foregroundColor(Color("FFC72C"))
                                        .font(.medium12)
                                }
                            
                            
                            SingleCornerRoundedRectangle(cornerRadius: 5, corners: [.topRight,.bottomRight])
                                .fill(Color("FFC72C"))
                                .frame(width: handleWidth, height: waveformHeight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black)
                                        .frame(width: 3 , height: 10)
                                )
                            
                                .gesture(
                                    DragGesture(coordinateSpace: .global)
                                        .onChanged { g in
                                            if dur0 == 0 {
                                                dur0 = segment.audioDuration
                                                crop0 = segment.audioStartTime
                                            }
                                            let proposedDX = g.location.x - g.startLocation.x
                                            rightDX = proposedDX

                                        }
                                        .onEnded { _ in
                                            segment.audioDuration = max(35, min(liveDur, segment.audioOriginalDuration - segment.audioStartTime))
                                            
                                          
                                            rightDX = 0
                                            dur0 = 0
                                        }
                                )
                            
                            
                        }
                        .frame(width: max(width,0))
                        .position(x: centerX, y: 32)

                    }
                    .overlay(alignment: .leading) {

                        Text(formatSecondsToMinutes(liveCrop))
                            .foregroundStyle(.black)
                            .font(.medium10)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                            .background(.white)
                            .clipShape(Capsule())
                            .offset(y : -50)
                            .position(x: leftX , y: 32)

//                            .offset(x: leftOffset)

                    }
                    
                }
                .frame(height: waveformHeight + 10)
                .environment(\.layoutDirection,  .leftToRight )
                .padding(.top,20)
                // Label for selected time
                
            }
            .padding(20)
            
        }
        .background(Color("27272F"))

        .onDisappear {
            player?.pause()
        }
    }
    
    private func togglePlay() {
        if isPlaying {
            player?.pause()
        } else {
            let start = segment.audioStartTime
            let duration = segment.audioDuration
            player = AVPlayer(url: segment.fileURL)
            player?.seek(to: CMTime(seconds: start, preferredTimescale: 600))
            player?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                player?.pause()
                isPlaying = false
            }
        }
        isPlaying.toggle()
    }
    func formatSecondsToMinutes(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60.0
        return String(format: "%.3f", minutes)
    }
}
#Preview {
    AudioCutterTabView(segment: .constant(AudioSegment(name: "test", fileURL: .applicationDirectory, audioOriginalDuration: 300, timeLineStartTime: 0, timeLineDuration: 20)))
        .background(Color("main-background"))
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .leftToRight )
    
    
}
