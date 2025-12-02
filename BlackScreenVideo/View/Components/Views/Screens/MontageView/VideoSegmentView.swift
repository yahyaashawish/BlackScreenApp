//
//  VideoSegmentView 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 16/11/2025.
//


import SwiftUI
struct VideoSegmentView: View {
    @ObservedObject var vm: MontageVM
    @Binding var segment: VideoSegment
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
                           segment.videoStartTime + Double(leftDX / pxPS * scale)
        )
        
        let liveDur =
            max(0.2, segment.timeLineDuration - Double(leftDX / pxPS * scale) + Double(rightDX / pxPS * scale))
        
        let width = liveDur * pxPS / scale
        let centerX = liveStart * pxPS / scale + width / 2
        
        HStack(spacing:0) {
            // LEFT HANDLE
            if isSelected {
                SingleCornerRoundedRectangle(cornerRadius: 5, corners: [.topLeft,.bottomLeft])
                    .fill(Color("34CC99"))
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
                                    crop0 = segment.videoStartTime
                                }
                                
                                let proposedLeftDX = g.location.x - g.startLocation.x
                                let proposedStart = start0 + Double(proposedLeftDX / vm.pixelsPerSecond * vm.timeScale)
                                let proposedVideoStart = crop0 + Double(proposedLeftDX / vm.pixelsPerSecond * vm.timeScale)
                                let proposedDuration = dur0 - Double(proposedLeftDX / vm.pixelsPerSecond * vm.timeScale)
                                
                                let proposedEnd = proposedStart + proposedDuration
                                
                                let hasConflict = vm.videoTrack.contains {
                                    $0.id != segment.id &&
                                    !(proposedEnd <= $0.timeLineStartTime || proposedStart >= $0.timeLineEndTime)
                                }
                                
                                if !hasConflict, proposedStart >= 0, proposedVideoStart >= 0, proposedDuration >= 0.2 {
                                    leftDX = proposedLeftDX
                                }
                            }
                            .onEnded { _ in
                                segment.timeLineStartTime = liveStart
                                segment.videoStartTime = liveCrop
                                segment.timeLineDuration = liveDur
                                leftDX = 0
                                dur0 = 0
                            }
                    )

            }
            
            
                    ZStack(alignment: .leading){
                       
                        if let thumb = segment.thumbnail{
                            TiledThumbnailView(uiImage: thumb)
                        }
                        
                        Text(segment.name)
                            .font(.medium12)
                            .foregroundColor(Color("34CC99"))
                            .padding(.leading,4)
                        
                    }
                    .background(Color("34CC99").opacity(0.15))

                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color("34CC99"), lineWidth: isSelected ? 2 : 0)
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
                                let conflict = vm.videoTrack.first {
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
                    .fill(Color("34CC99"))
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
                                
                                // Limit to remaining video duration
//                                let maxVideoDuration = segment.videoDuration - segment.videoStartTime
//                                
//                                // Limit to next segment start if exists
                                if let nextSegment = vm.videoTrack
                                    .filter({ $0.id != segment.id && $0.timeLineStartTime >= segment.timeLineEndTime })
                                    .sorted(by: { $0.timeLineStartTime < $1.timeLineStartTime })
                                    .first {
                                    
                                    let maxBeforeNext = nextSegment.timeLineStartTime - segment.timeLineStartTime
                                    proposedDuration = min(proposedDuration, maxBeforeNext)
                                }
                                
//                                proposedDuration = min(proposedDuration, maxVideoDuration)
//                                proposedDuration = max(0.2, proposedDuration)
//                                
                                // Convert back to visual drag
                                rightDX = (proposedDuration - dur0) * vm.pixelsPerSecond / vm.timeScale
                            }
                            .onEnded { _ in
                                let finalDuration = dur0 + Double(rightDX / vm.pixelsPerSecond * vm.timeScale)
                                print("finalDuration: \(finalDuration)")
                                segment.timeLineDuration =  max(0.2, finalDuration)
                                print("segment.timeLineDuration: \(segment.timeLineDuration)")
                                rightDX = 0
                                dur0 = 0
                            }
                    )




            }
           
        }

        .position(x: centerX, y: trackY)
        .onTapGesture {
            withAnimation(.bouncy) {
                vm.selectVideoSegment(segment: segment)
            }
        }
        .animation(nil, value: dragDX)
        .animation(nil, value: leftDX)
        .animation(nil, value: rightDX)

    }
}
struct TiledThumbnailView: View {
    let uiImage: UIImage
    let height: CGFloat = 30
    
    var body: some View {
            GeometryReader { geo in

                Canvas { context, size in
                    
                    // Convert UIImage → SwiftUI Image
                    let image = Image(uiImage: uiImage)
                    
                    // Resolve to ResolvedImage (non-optional)
                    let resolved = context.resolve(image)
                    
                    let tileSize = CGSize(width: height, height: height)
                    
                    var x: CGFloat = 0
                    while x < size.width {
                        context.draw(
                            resolved,
                            in: CGRect(x: x,
                                       y: 0,
                                       width: tileSize.width,
                                       height: tileSize.height)
                        )
                        x += tileSize.width
                    }
                }
            }
            .frame(height: height)
            .clipped()
        
        
    }
}
