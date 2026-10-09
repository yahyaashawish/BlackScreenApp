//
//  AudioCutterTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
import AVFoundation

struct AudioCutterTabView: View {
    @Binding var segment : AudioSegment
    var onCommit: (_ audioStartTime: TimeInterval, _ timeLineDuration: TimeInterval) -> Void = { _, _ in }
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var playbackEndTask: Task<Void, Never>?

    let waveformHeight: CGFloat = 54

//    @State var audioSegment : AudioSegment = AudioSegment(name: "test", fileURL: .applicationDirectory, audioOriginalDuration: 300, timeLineStartTime: 0, timeLineDuration: 20)
    
    @State private var leftDX: CGFloat = 0
    @State private var rightDX: CGFloat = 0
    @State private var selectionDX: CGFloat = 0
    let handleWidth: Double = 20
    private let minimumDuration: TimeInterval = 0.2
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
                    let sourceDuration = max(0, segment.audioOriginalDuration)
                    let effectiveMinimumDuration = min(minimumDuration, sourceDuration)
                    let pxPS = max(
                        geo.size.width / max(sourceDuration, minimumDuration),
                        .leastNonzeroMagnitude
                    )

                    let availableDuration = min(
                        max(0, segment.audioDuration),
                        max(0, sourceDuration - segment.audioStartTime)
                    )
                    let currentDuration = min(
                        max(effectiveMinimumDuration, segment.timeLineDuration),
                        availableDuration
                    )
                    let requestedCrop = segment.audioStartTime + Double(leftDX / pxPS)
                    let maximumCrop = max(0, sourceDuration - effectiveMinimumDuration)
                    let resizedCrop = min(max(0, requestedCrop), maximumCrop)
                    let maxDuration = min(
                        max(0, segment.audioDuration),
                        max(0, sourceDuration - resizedCrop)
                    )
                    let resizedDuration = min(
                        max(effectiveMinimumDuration, currentDuration - (resizedCrop - segment.audioStartTime) + Double(rightDX / pxPS)),
                        maxDuration
                    )
                    let requestedSelectionCrop = resizedCrop + Double(selectionDX / pxPS)
                    let liveCrop = min(
                        max(0, requestedSelectionCrop),
                        max(0, sourceDuration - resizedDuration)
                    )
                    let liveDur = resizedDuration
                    let width = (liveDur * pxPS)
                    let centerX = liveCrop * pxPS  + width / 2
                    let leftX = centerX - width / 2 + handleWidth
                    let selectionHitExpansion = max(0, (44 - width) / 2)
                    
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
                                .highPriorityGesture(
                                    DragGesture(coordinateSpace: .global)
                                        .onChanged { g in
                                            let proposedLeftDX = g.location.x - g.startLocation.x
                                            leftDX = proposedLeftDX
                                        }
                                        .onEnded { _ in
                                            commitTrim(startTime: liveCrop, duration: liveDur)

                                            leftDX = 0
                                        }
                                )
                               


                            Rectangle()
                                .fill(.clear)
                                .frame(height: waveformHeight-2)
                                .contentShape(Rectangle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color("FFC72C"), lineWidth: 2)
                                )
                                .overlay {
                                    Text(formatDuration(liveDur))
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
                            
                                .highPriorityGesture(
                                    DragGesture(coordinateSpace: .global)
                                        .onChanged { g in
                                            let proposedDX = g.location.x - g.startLocation.x
                                            rightDX = proposedDX

                                        }
                                        .onEnded { _ in
                                            commitTrim(startTime: liveCrop, duration: liveDur)

                                            rightDX = 0
                                        }
                                )
                        
                            
                        }
                        .frame(width: max(width,0))
                        .contentShape(Rectangle().inset(by: -selectionHitExpansion))
                        .gesture(
                            DragGesture(coordinateSpace: .global)
                                .onChanged { gesture in
                                    selectionDX = gesture.location.x - gesture.startLocation.x
                                }
                                .onEnded { _ in
                                    commitTrim(startTime: liveCrop, duration: liveDur)
                                    selectionDX = 0
                                }
                        )
                        .position(x: centerX, y: 32)
                        .animation(nil, value: selectionDX)

                    }
                    .overlay(alignment: .leading) {

                        Text(formatDuration(liveCrop))
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
            stopPlayback()
        }
    }

    private func commitTrim(startTime: TimeInterval, duration: TimeInterval) {
        stopPlayback()

        let sourceDuration = max(0, segment.audioOriginalDuration)
        let effectiveMinimumDuration = min(minimumDuration, sourceDuration)
        let safeStart = min(max(0, startTime), max(0, sourceDuration - effectiveMinimumDuration))
        let availableDuration = min(
            max(0, segment.audioDuration),
            max(0, sourceDuration - safeStart)
        )
        let safeDuration = min(
            max(effectiveMinimumDuration, duration),
            availableDuration
        )

        onCommit(safeStart, safeDuration)
    }

    private func stopPlayback() {
        playbackEndTask?.cancel()
        playbackEndTask = nil
        player?.pause()
        player = nil
        isPlaying = false
    }
    
    private func togglePlay() {
        if isPlaying {
            stopPlayback()
        } else {
            let start = segment.audioStartTime
            let sourceRemainingDuration = max(0, segment.audioOriginalDuration - start)
            let duration = min(
                max(0, segment.timeLineDuration),
                max(0, segment.audioDuration),
                sourceRemainingDuration
            )
            guard start.isFinite, duration.isFinite, duration > 0 else { return }

            playbackEndTask?.cancel()
            player = AVPlayer(url: segment.fileURL)
            player?.seek(to: CMTime(seconds: start, preferredTimescale: 600))
            player?.play()
            isPlaying = true

            playbackEndTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(duration))
                    guard !Task.isCancelled else { return }
                    stopPlayback()
                } catch {
                    // Cancellation is expected when playback is paused or restarted.
                }
            }
        }
    }
    private func formatDuration(_ duration: TimeInterval) -> String {
        guard duration.isFinite, duration >= 0 else {
            return "0:00"
        }

        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
#Preview {
    AudioCutterTabView(segment: .constant(AudioSegment(name: "test", fileURL: .applicationDirectory, audioOriginalDuration: 300, timeLineStartTime: 0, timeLineDuration: 20)))
        .background(Color("main-background"))
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .leftToRight )
    
    
}
