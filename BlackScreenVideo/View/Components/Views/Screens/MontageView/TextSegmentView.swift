//
//  TextSegmentView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 24/07/2025.
//

import SwiftUI
struct TextSegmentView: View {
    @ObservedObject var vm: MontageVM
    @Binding var seg: TextSegment                         // real model
    let trackY: CGFloat = 16                               // y-center for this row
    let isSelected: Bool
    // live preview
    @State private var dragDX: CGFloat = 0                // whole-segment move
    @State private var leftDX: CGFloat = 0                // left-edge resize
    @State private var rightDX: CGFloat = 0               // right-edge resize
    
    // snapshots captured at drag start
    @State private var start0: TimeInterval = 0
    @State private var dur0  : TimeInterval = 0
    
    var body: some View {
        
        // ---- constants ----
        let pxPS   = vm.pixelsPerSecond
        let scale  = vm.timeScale
        let handle = CGFloat(20)
        
        // ---- live preview math ----
        let liveStart  = max(0,
                             seg.startTime + Double(dragDX / pxPS * scale) + Double(leftDX / pxPS * scale)
        )
        let liveDur    = max(0.2,
                             seg.duration - Double(leftDX / pxPS * scale) + Double(rightDX / pxPS * scale)
        )
        
        let width  = liveDur   * pxPS / scale
        let center = liveStart * pxPS / scale + width / 2
        
        HStack(spacing: 0) {                                    // -------------  ROW  -------------
            //  left handle  ───────────────────────────────────────────────────────────
            if isSelected {
                SingleCornerRoundedRectangle(cornerRadius: 5, corners: [.topLeft,.bottomLeft])
                    .fill(Color("01B5FF"))
                    .frame(width: handle, height: 32)
                    .overlay(Image("chev-left"))
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { g in
                                if dur0 == 0 { start0 = seg.startTime; dur0 = seg.duration }
                                leftDX = g.location.x - g.startLocation.x
                            }
                            .onEnded { _ in
                                seg.startTime = liveStart
                                seg.duration  = liveDur
                                let newStart = seg.startTime
                                let newEnd = seg.endTime
                                
                                // Check for overlap with any other segment in any track
                                if let newTrack = vm.vacantTrackIndex(for: newStart, end: newEnd, ignoring: seg.id) {
                                    if newTrack != seg.trackIndex {
                                        vm.move(seg, toTrack: newTrack)
                                    }
                                } else {
                                    vm.move(seg, toTrack: vm.textTracks.count) // New track
                                }
                                leftDX = .zero; dur0 = 0
    
                            }
                    )
            }
            
            
            //  main body  ─────────────────────────────────────────────────────────────
            Rectangle()
                .fill(Color("01B5FF").opacity(0.25))
                .overlay(
                    HStack{
                        Text(seg.content)
                            .font(.medium12)
                            .foregroundColor(Color("01B5FF"))
                            .padding(.leading,4)
                        
                        Spacer()
                        if seg.transitionType != .none {
                            Image(seg.transitionType.icon)
                                .resizable()
                                .frame(width: 9,height: 9)
                                .foregroundStyle(Color("01B5FF"))
                                .padding(.trailing,4)
                        }
                        
                    }
                    , alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color("01B5FF"), lineWidth: isSelected ? 2 : 0)
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { g in
                            vm.pausePreviewPlayback()
                            if start0 == 0 { start0 = seg.startTime }
                            dragDX = g.translation.width
                        }
                        .onEnded { _ in
                            seg.startTime = liveStart
                            dragDX = .zero; start0 = 0
                            
                            let newStart = seg.startTime
                            let newEnd = seg.endTime
                           
                            // Check for overlap with any other segment in any track
                            if let newTrack = vm.vacantTrackIndex(for: newStart, end: newEnd, ignoring: seg.id) {
                                if newTrack != seg.trackIndex {
                                    vm.move(seg, toTrack: newTrack)
                                }
                            } else {
                                vm.move(seg, toTrack: vm.textTracks.count) // New track
                            }

                        }
                )
                .frame(width: max(width,0), height: isSelected ? 30 : 20)

            
            //  right handle  ──────────────────────────────────────────────────────────
            if isSelected {
                SingleCornerRoundedRectangle(cornerRadius: 5, corners: [.topRight,.bottomRight])
                    .fill(Color("01B5FF"))
                    .frame(width: handle, height: 32)
                    .overlay(Image("chev-right"))
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { g in
                                if dur0 == 0 { dur0 = seg.duration }
                                rightDX = g.location.x - g.startLocation.x
                            }
                            .onEnded { _ in
                                seg.duration = liveDur
                                let newStart = seg.startTime
                                let newEnd = seg.endTime
                                
                                // Check for overlap with any other segment in any track
                                if let newTrack = vm.vacantTrackIndex(for: newStart, end: newEnd, ignoring: seg.id) {
                                    if newTrack != seg.trackIndex {
                                        vm.move(seg, toTrack: newTrack)
                                    }
                                } else {
                                    vm.move(seg, toTrack: vm.textTracks.count) // New track
                                }
                                rightDX = .zero; dur0 = 0

                            }
                    )
            }
            
            
        }
        .position(x: center, y: trackY)
        .onTapGesture {
            withAnimation(.bouncy) {
                vm.selectTextSegment(segment: seg)
            }
        }
        // absolute – no HStack jitter
        .animation(nil, value: dragDX)                          // disable implicit spring
        .animation(nil, value: leftDX)
        .animation(nil, value: rightDX)
    }
}
