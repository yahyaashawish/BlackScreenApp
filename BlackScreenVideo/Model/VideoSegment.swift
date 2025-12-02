//
//  AudioSegment 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 16/11/2025.
//


import Foundation
import UIKit
struct VideoSegment: Identifiable, Equatable {
    let id: UUID
    let name : String
    let fileURL: URL
    var thumbnail : UIImage?
    let videoOriginalDuration: TimeInterval
    var videoDuration: TimeInterval {
        return videoOriginalDuration - videoStartTime
    }
    var videoStartTime: TimeInterval
    var timeLineStartTime: TimeInterval
    var timeLineDuration: TimeInterval
    var timeLineEndTime: TimeInterval {
        timeLineStartTime + timeLineDuration
    }
    private var internalVolume: Float
    let maxVolume = PropertiesConstants.MaximumVolume
    var volume: Float {
        get {
            return ( internalVolume / maxVolume ) * 100
        }
        set {
            internalVolume = ( newValue / 100 ) * maxVolume
        }
    }
    var actualVolume: Float {
        internalVolume
    }


    init(
        id: UUID = UUID(),
        name : String,
        fileURL: URL,
        thumbnail : UIImage?,
        videoOriginalDuration :TimeInterval,
        timeLineStartTime: TimeInterval,
        timeLineDuration: TimeInterval,
        volume: Float = 80.0,

    ) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.thumbnail = thumbnail
        self.videoOriginalDuration = videoOriginalDuration
        self.videoStartTime = 0
        self.timeLineStartTime = timeLineStartTime
        self.timeLineDuration = timeLineDuration
        self.internalVolume = ( volume / 100 ) * maxVolume

    }
    init(
        id: UUID = UUID(),
        name : String,
        fileURL: URL,
        thumbnail : UIImage?,
        videoOriginalDuration :TimeInterval,
        videoStartTime :TimeInterval,
        timeLineStartTime: TimeInterval,
        timeLineDuration: TimeInterval,
        volume: Float = 80.0,
        
    ) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.thumbnail = thumbnail
        self.videoOriginalDuration = videoOriginalDuration
        self.videoStartTime = videoStartTime
        self.timeLineStartTime = timeLineStartTime
        self.timeLineDuration = timeLineDuration
        self.internalVolume = ( volume / 100 ) * maxVolume
        
    }


}
