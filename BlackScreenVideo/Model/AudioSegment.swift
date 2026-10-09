//
//  AudioSegment.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 28/05/2025.
//



import Foundation

struct AudioSegment: Identifiable, Equatable {
    let id: UUID
    var name : String
    var fileURL: URL
    /// Total duration of the underlying source file.
    let audioOriginalDuration: TimeInterval
    /// Maximum source-audio length available to this segment.
    /// This is a capacity, not necessarily the length currently shown on the timeline.
    var audioDuration: TimeInterval
    /// Start offset, in seconds, inside the source audio file.
    var audioStartTime: TimeInterval
    /// Position, in seconds, where the segment begins in the montage timeline.
    var timeLineStartTime: TimeInterval
    /// Audio length currently used for timeline layout, preview, and export.
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
    var fadeInDuration: TimeInterval
    var fadeOutDuration: TimeInterval
    var amplitudes: [CGFloat] = []
    
    var croppedAmplitudes: [CGFloat] {
        let totalSamples = amplitudes.count
        let totalDuration = audioOriginalDuration
        guard totalSamples > 0,
              totalDuration.isFinite,
              totalDuration > 0,
              audioStartTime.isFinite,
              timeLineDuration.isFinite,
              timeLineDuration > 0 else {
            return []
        }

        let cropStart = min(max(0, audioStartTime), totalDuration)
        let cropEnd = min(max(cropStart, cropStart + timeLineDuration), totalDuration)
        
        // Fractional positions in the full waveform
        let startRatio = min(max(cropStart / totalDuration, 0), 1)
        let endRatio = min(max(cropEnd / totalDuration, startRatio), 1)
        
        // Slice of waveform to show
        let startIndex = min(max(Int(CGFloat(totalSamples) * CGFloat(startRatio)), 0), totalSamples)
        let endIndex = min(max(Int(CGFloat(totalSamples) * CGFloat(endRatio)), startIndex), totalSamples)
        
        return Array(amplitudes[startIndex..<endIndex])
    }

    init(
        id: UUID = UUID(),
        name : String,
        fileURL: URL,
        audioOriginalDuration :TimeInterval,
        timeLineStartTime: TimeInterval,
        timeLineDuration: TimeInterval,
        volume: Float = 80.0,
        fadeInDuration: TimeInterval = 0,
        fadeOutDuration: TimeInterval = 0,
        amplitudes: [CGFloat] = []
    ) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.audioOriginalDuration = audioOriginalDuration
        self.audioDuration = audioOriginalDuration
        self.audioStartTime = 0
        self.timeLineStartTime = timeLineStartTime
        self.timeLineDuration = timeLineDuration
        self.internalVolume = ( volume / 100 ) * maxVolume
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
        self.amplitudes = amplitudes
    }
    
    init(
        id: UUID = UUID(),
        name : String,
        fileURL: URL,
        audioOriginalDuration :TimeInterval,
        audioDuration :TimeInterval,
        audioStartTime:TimeInterval,
        timeLineStartTime: TimeInterval,
        timeLineDuration: TimeInterval,
        volume: Float = 80.0,
        fadeInDuration: TimeInterval = 0,
        fadeOutDuration: TimeInterval = 0,
        amplitudes: [CGFloat] = []
    ) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.audioOriginalDuration = audioOriginalDuration
        self.audioDuration = audioDuration
        self.audioStartTime = audioStartTime
        self.timeLineStartTime = timeLineStartTime
        self.timeLineDuration = timeLineDuration
        self.internalVolume = ( volume / 100 ) * maxVolume
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
        self.amplitudes = amplitudes
    }


}
