//
//  AudioWaveformProvider.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 17/06/2025.
//


import AVFoundation
import SwiftUI

class AudioWaveFormLoader: ObservableObject {

    static func loadWaveform(from url: URL, sampleCount: Int = 200,completion: @escaping ([CGFloat]) -> Void) {
        Task {
            var samples: [CGFloat] = []
            
            let asset = AVURLAsset(url: url)
            
            do {
                let tracks = try await asset.loadTracks(withMediaType: .audio)
                guard let track = tracks.first else { return }
                
                let readerSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMIsFloatKey: true,
                    AVLinearPCMBitDepthKey: 32,
                    AVLinearPCMIsNonInterleaved: false
                ]
                
                let reader = try AVAssetReader(asset: asset)
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: readerSettings)
                reader.add(output)
                
                var bufferSamples: [CGFloat] = []
                
                reader.startReading()
                
                while reader.status == .reading {
                    guard let sampleBuffer = output.copyNextSampleBuffer(),
                          let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                        break
                    }
                    
                    let length = CMBlockBufferGetDataLength(blockBuffer)
                    var data = [Float](repeating: 0, count: length / MemoryLayout<Float>.size)
                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &data)
                    
                    let rms = sqrt(data.map { $0 * $0 }.reduce(0, +) / Float(data.count))
                    bufferSamples.append(CGFloat(rms))
                }
                
                // Downsample
                let groupSize = max(1, bufferSamples.count / sampleCount)
                for i in stride(from: 0, to: bufferSamples.count, by: groupSize) {
                    let group = bufferSamples[i..<min(i+groupSize, bufferSamples.count)]
                    let avg = group.reduce(0, +) / CGFloat(group.count)
                    samples.append(avg)
                }
                
                let maxVal = samples.max() ?? 1
                let normalized = samples.map { $0 / maxVal }
                
                completion(normalized)
                
            } catch {
                print("Waveform load error:", error)
            }
        }
    }
    
    static func croppedWaveform(
        for full: [CGFloat],
        audioStartTime: TimeInterval,
        duration: TimeInterval,
        originalDuration: TimeInterval,
        minimumSamples: Int = 30
    ) -> [CGFloat] {
        guard !full.isEmpty, originalDuration > 0 else { return [] }
        
        let startRatio = max(0, audioStartTime / originalDuration)
        let endRatio = min(1, (audioStartTime + duration) / originalDuration)
        
        var startIndex = Int(CGFloat(full.count) * CGFloat(startRatio))
        var endIndex = Int(CGFloat(full.count) * CGFloat(endRatio))
        
        if startIndex >= endIndex {
            // ensure at least `minimumSamples`
            endIndex = min(startIndex + minimumSamples, full.count)
        }
        
        return Array(full[startIndex..<min(endIndex, full.count)])
    }
    
    static func loadWaveFormForAudioS(segment : AudioSegment,completion: @escaping ([CGFloat]) -> Void){
        AudioWaveFormLoader.loadWaveform(from: segment.fileURL) { full in
            completion(full)
        }
            
    }
}
