//
//  AudioSegmentView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 24/07/2025.
//

import SwiftUI
struct AudioSegmentView: View {
    @ObservedObject var vm: MontageVM
    @Binding var segment: AudioSegment
    let trackY: CGFloat = 16                               // y-center for this row
    let isSelected: Bool

    @State private var dragDX: CGFloat = 0
    @State private var leftDX: CGFloat = 0
    @State private var rightDX: CGFloat = 0
    @State private var start0: TimeInterval = 0
    @State private var dur0: TimeInterval = 0
    @State private var crop0: TimeInterval = 0
    
    var body: some View {
        let pxPS = vm.pixelsPerSecond
        let scale = vm.timeScale
        let handle: CGFloat = 20
        
        // Live state
        let liveStart = max(0,
                            segment.timeLineStartTime + Double(dragDX / pxPS * scale) + Double(leftDX / pxPS * scale)
        )
        
        let liveCrop = max(0,
                           segment.audioStartTime + Double(leftDX / pxPS * scale)
        )
        
        let maxCrop = segment.audioDuration - liveCrop
        let liveDur = min(
            max(0.2, segment.timeLineDuration - Double(leftDX / pxPS * scale) + Double(rightDX / pxPS * scale)),
            maxCrop
        )
        
        let width = liveDur * pxPS / scale
        let centerX = liveStart * pxPS / scale + width / 2
        
        HStack(spacing:0) {
            // LEFT HANDLE
            if isSelected {
                SingleCornerRoundedRectangle(cornerRadius: 5, corners: [.topLeft,.bottomLeft])
                    .fill(Color("FFC72C"))
                    .frame(width: handle, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black)
                            .frame(width: 3 , height: 10)
                    )
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { g in
                                if dur0 == 0 {
                                    dur0 = segment.timeLineDuration
                                    start0 = segment.timeLineStartTime
                                    crop0 = segment.audioStartTime
                                }
                                
                                let proposedLeftDX = g.location.x - g.startLocation.x
                                let proposedStart = start0 + Double(proposedLeftDX / vm.pixelsPerSecond * vm.timeScale)
                                let proposedAudioStart = crop0 + Double(proposedLeftDX / vm.pixelsPerSecond * vm.timeScale)
                                let proposedDuration = dur0 - Double(proposedLeftDX / vm.pixelsPerSecond * vm.timeScale)
                                
                                let proposedEnd = proposedStart + proposedDuration
                                
                                let hasConflict = vm.audioSegments.contains {
                                    $0.id != segment.id &&
                                    !(proposedEnd <= $0.timeLineStartTime || proposedStart >= $0.timeLineEndTime)
                                }
                                
                                if !hasConflict, proposedStart >= 0, proposedAudioStart >= 0, proposedDuration >= 0.2 {
                                    leftDX = proposedLeftDX
                                }
                            }
                            .onEnded { _ in
                                segment.timeLineStartTime = liveStart
                                segment.audioStartTime = liveCrop
                                segment.timeLineDuration = liveDur
                                leftDX = 0
                                dur0 = 0
                            }
                    )

            }
            
            
            // MAIN BODY (with waveform)
            Rectangle()
                .fill(Color("FFC72C").opacity(0.15))
                .overlay(
                    ZStack(alignment: .leading){
                        WaveformView(amplitudes: segment.croppedAmplitudes,width: width)
                            .clipped()
                        
                        Text(segment.name)
                            .font(.medium12)
                            .foregroundColor(Color("FFC72C"))
                            .padding(.leading,4)
                        
                    }
                    
                    , alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color("FFC72C"), lineWidth: isSelected ? 2 : 0)
                )
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { g in
                            vm.pausePreviewPlayback()
                            if start0 == 0 {
                                start0 = segment.timeLineStartTime
                            }
                            dragDX = g.translation.width
                        }
                        .onEnded { _ in
                            var proposedStart = start0 + Double(dragDX / vm.pixelsPerSecond * vm.timeScale)
                            var proposedEnd = proposedStart + segment.timeLineDuration
                            
                            let currentSegmentID = segment.id
                            
                            // Keep looping until no conflicts
                            while true {
                                // Check for any overlap
                                let conflict = vm.audioSegments.first {
                                    $0.id != currentSegmentID &&
                                    !(proposedEnd <= $0.timeLineStartTime || proposedStart >= $0.timeLineEndTime)
                                }
                                
                                if let conflict = conflict {
                                    // Move it after the conflicting one
                                    proposedStart = conflict.timeLineStartTime + conflict.timeLineDuration + 0.01
                                    proposedEnd = proposedStart + segment.timeLineDuration
                                } else {
                                    // No conflict – finalize
                                    break
                                }
                            }
                            
                            segment.timeLineStartTime = max(0, proposedStart)
                            dragDX = 0
                            start0 = 0
                        }
                )




                .frame(width: max(width,0), height: 30)

            
            // RIGHT HANDLE
            if isSelected {
                SingleCornerRoundedRectangle(cornerRadius: 5, corners: [.topRight,.bottomRight])
                    .fill(Color("FFC72C"))
                    .frame(width: handle, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black)
                            .frame(width: 3 , height: 10)
                    )
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { g in
                                if dur0 == 0 {
                                    dur0 = segment.timeLineDuration
                                }
                                
                                let proposedDX = g.location.x - g.startLocation.x
                                var proposedDuration = dur0 + Double(proposedDX / vm.pixelsPerSecond * vm.timeScale)
                                
                                // Limit to remaining audio duration
                                let maxAudioDuration = segment.audioDuration - segment.audioStartTime
                                
                                // Limit to next segment start if exists
                                if let nextSegment = vm.audioSegments
                                    .filter({ $0.id != segment.id && $0.timeLineStartTime >= segment.timeLineEndTime })
                                    .sorted(by: { $0.timeLineStartTime < $1.timeLineStartTime })
                                    .first {
                                    
                                    let maxBeforeNext = nextSegment.timeLineStartTime - segment.timeLineStartTime
                                    proposedDuration = min(proposedDuration, maxBeforeNext)
                                }
                                
                                proposedDuration = min(proposedDuration, maxAudioDuration)
                                proposedDuration = max(0.2, proposedDuration)
                                
                                // Convert back to visual drag
                                rightDX = (proposedDuration - dur0) * vm.pixelsPerSecond / vm.timeScale
                            }
                            .onEnded { _ in
                                let finalDuration = dur0 + Double(rightDX / vm.pixelsPerSecond * vm.timeScale)
                                segment.timeLineDuration = min(segment.audioDuration - segment.audioStartTime, max(0.2, finalDuration))
                                rightDX = 0
                                dur0 = 0
                            }
                    )




            }
           
        }

        .position(x: centerX, y: trackY)
        .onTapGesture {
            withAnimation(.bouncy) {
                vm.selectAudioSegment(segment: segment)

            }
        }
        .animation(nil, value: dragDX)
        .animation(nil, value: leftDX)
        .animation(nil, value: rightDX)
        .onAppear {
            if segment.amplitudes.isEmpty{
                AudioWaveFormLoader.loadWaveFormForAudioS(segment: segment) { amps in
                    DispatchQueue.main.async {
                        self.segment.amplitudes = amps
                    }
                }
            }
            
        }
    }
}
struct WaveformView: View {
    var amplitudes: [CGFloat]
    let width: CGFloat
    var height : CGFloat = 30
    var body: some View {
        let barCount = amplitudes.count
        let barWidth: CGFloat = 2   // Fixed capsule width
        let totalBarWidth = CGFloat(barCount) * barWidth
        let availableSpacing = max(width - totalBarWidth, 0)
        let spacing = availableSpacing / CGFloat(max(barCount - 1, 1))
        
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { i in
                let amp = amplitudes[i]
                Capsule()
                    .fill(Color("FFC72C").opacity(0.2))
                    .frame(width: barWidth, height: max(1, amp * height))
            }
        }
        .frame(width: width, height: height, alignment: .center)
    }
}

