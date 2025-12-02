//
//  TextSegmentContentRenderer 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 20/11/2025.
//



import SwiftUI
import AVFoundation

struct ActualSegmentPlayerItems {
    let segment: VideoSegment
    let items : [AVPlayerItem]
}

class VideoPreviewManager {
    
    func buildActualSegmentPlayerItems(
        segment: VideoSegment
    ) -> [AVPlayerItem] {
        
        
        // 4. Generate actual playable videos
                let timeLineDuration = segment.timeLineDuration
                let originalDuration = segment.videoOriginalDuration
                let isExtendedTimeLineDuration = segment.timeLineDuration > segment.videoDuration
                
                
        var playerItems : [AVPlayerItem] = []
        
        let asset = AVURLAsset(url: segment.fileURL)
        let firstItem = AVPlayerItem(asset: asset)
        
        playerItems.append(firstItem)
        
                if isExtendedTimeLineDuration {
                    let remainingTimeLineDuration = timeLineDuration - segment.videoDuration
                    let partsCount = ceil(remainingTimeLineDuration/originalDuration)
                    
                    for _ in 1...Int(partsCount) {
                        let item = AVPlayerItem(asset: asset)
                        playerItems.append(item)
                    }
        }
        return playerItems
    }


    func prepareSegmentsActualQueuePlayers(
        segments: [VideoSegment],
    ) -> [ActualSegmentPlayerItems]{
        var segmentsPlayerItems: [ActualSegmentPlayerItems] = []
        for segment in segments {
            let segmentItems = buildActualSegmentPlayerItems(segment: segment)
            if !segmentItems.isEmpty {
                let segmentPlayerItems = ActualSegmentPlayerItems(segment: segment, items: segmentItems)
                segmentsPlayerItems.append(segmentPlayerItems)
            }

        }
        return segmentsPlayerItems
        
        

    }

}
