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
    let audioOriginalDuration: TimeInterval
    var audioDuration: TimeInterval  // actual duration of audio
    var audioStartTime: TimeInterval
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
    var fadeInDuration: TimeInterval
    var fadeOutDuration: TimeInterval
    var amplitudes: [CGFloat] = []
    
    var croppedAmplitudes: [CGFloat] {
        let totalSamples = self.amplitudes.count
        let totalDuration = self.audioOriginalDuration
        let cropStart = self.audioStartTime
        let cropEnd = cropStart + self.timeLineDuration
        
        // Fractional positions in the full waveform
        let startRatio = cropStart / totalDuration
        let endRatio = min(cropEnd / totalDuration, 1.0)
        
        // Slice of waveform to show
        let startIndex = Int(CGFloat(totalSamples) * CGFloat(startRatio))
        let endIndex = Int(CGFloat(totalSamples) * CGFloat(endRatio))
        
        let visibleAmplitudes = Array(self.amplitudes[startIndex..<min(endIndex, totalSamples)])
        return visibleAmplitudes
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
