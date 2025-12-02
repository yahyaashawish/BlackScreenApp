import Foundation
import AVFoundation
import UIKit
import CoreGraphics
import SwiftUI
enum MediaExportError: Error {
    case couldNotCreateExportSession
    case noContent
    case compositionFailed
}

enum MediaComposeError: Error {
    case noVideoInVideoURL
    case noAudioInAudioURL
    case couldNotCreateVideoTrack
    case couldNotCreateAudioTrack
    case couldNotCreateAVAssetFromComposition
}
enum ExportLayersError: LocalizedError {
    case videoCreationFailed
    case textOverlayFailed
    case audioMixingFailed
    case finalCompositionFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .videoCreationFailed:
            return "Failed to create base video from video segments"
        case .textOverlayFailed:
            return "Failed to add text overlays to video"
        case .audioMixingFailed:
            return "Failed to mix audio segments"
        case .finalCompositionFailed:
            return "Failed to compose final video"
        case .cancelled:
            return "Export was cancelled"
        }
    }
}
import AVFoundation
import UIKit

public class VideoExportManager {
    let videoSize: CGSize
    let previewSize : CGSize
    let fps: Int32 = 30
    private var cachedBlackVideoURL: URL?
    private let blackVideoDuration: Double = 60.0 // 1 minute
    
    var backgroundVideoURL: URL? = nil
    init(videoSize: CGSize, previewSize : CGSize) {
        self.videoSize = videoSize
        self.previewSize = previewSize
    }
    
    // Property to store the current export task for cancellation
    private(set) var currentExportVideoLayerTask: Task<Void, Never>?
    private(set) var currentExportBlackVideoLayerTask: Task<Void, Never>?
    private(set) var currentExportVideoTextLayerTask: TextOverlayCancellable?
    private(set) var currentExportTask: Task<Void, Never>?
    
    @MainActor
    func exportVideo(
        textSegments: [[TextSegment]],
        audioSegments: [AudioSegment],
        videoSegments: [VideoSegment],
        duration: Double,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Cancel any existing export task
        currentExportTask?.cancel()
        
        // Create new export task
        currentExportTask = Task {
            do {
                // Progress weights for each step
                let videoCreationWeight = 0.40      // 30% - Creating base video
                let textOverlayWeight = 0.45        // 60% - Adding text overlays
                let audioMixingWeight = 0.10        // 5% - Mixing audio
                
                var currentProgress: Double = 0.0
                
                // STEP 1: Create base video from video segments (0% - 35%)
                let baseVideoURL = try await withCheckedThrowingContinuation { continuation in
                    self.exportVideoSegments(
                        segments: videoSegments,
                        fullDuration: duration,
                        renderSize: self.videoSize,
                        progressHandler: { progress in
                            let adjustedProgress = currentProgress + (progress * videoCreationWeight)
                            progressHandler(adjustedProgress)
                        },
                        completion: { url in
                            if let url = url {
                                continuation.resume(returning: url)
                            } else {
                                continuation.resume(throwing: ExportLayersError.videoCreationFailed)
                            }
                        }
                    )
                }
                
                // Check for cancellation
                try Task.checkCancellation()
                currentProgress = videoCreationWeight
                progressHandler(currentProgress)
                
                // STEP 2: Add text overlays to video (35% - 70%)
                let videoWithTextURL = try await withCheckedThrowingContinuation { continuation in
                    self.currentExportVideoTextLayerTask = self.addTextOverlayToVideo(
                        videoURL: baseVideoURL,
                        textSegments: textSegments,
                        renderSize: self.videoSize, // Should match step 1
                        previewSize: self.previewSize, // Adjust based on your preview
                        progressHandler: { progress in
                            let adjustedProgress = currentProgress + (progress * textOverlayWeight)
                            progressHandler(adjustedProgress)
                        },
                        completion: { url in
                            if let url = url {
                                continuation.resume(returning: url)
                            } else {
                                continuation.resume(throwing: ExportLayersError.textOverlayFailed)
                            }
                        }
                    )
                }
                
                // Check for cancellation
                try Task.checkCancellation()
                currentProgress = videoCreationWeight + textOverlayWeight
                progressHandler(currentProgress)
                
                // STEP 3: Mix audio segments (70% - 85%)
                let mixedAudioURL = await self.mixAudioSegments(audioSegments: audioSegments)
                
                // Check for cancellation
                try Task.checkCancellation()
                currentProgress = videoCreationWeight + textOverlayWeight + audioMixingWeight
                progressHandler(currentProgress)
                
                // STEP 4: Compose final video with all layers (85% - 100%)
                let outputDirectory = FileManager.default.temporaryDirectory
                let outputName = "final_video_\(UUID().uuidString)"
                
                let finalVideoURL = try await self.composeFinalVideoLayers(
                    videoURL: videoWithTextURL,
                    audioURL: mixedAudioURL,
                    videoTrackAudio: baseVideoURL, // Extract audio from original video
                    outputName: outputName,
                    outputFormat: .mp4,
                    outputDirectory: outputDirectory
                )
                
                // Check for cancellation
                try Task.checkCancellation()
                
                // Complete - 100%
                progressHandler(1.0)
                
                // Cleanup temporary files
                self.cleanupTemporaryFiles([baseVideoURL, videoWithTextURL, mixedAudioURL])
                
                // Return success
                await MainActor.run {
                    completion(.success(finalVideoURL))
                }
                
            } catch is CancellationError {
                // Task was cancelled
                await MainActor.run {
                    completion(.failure(ExportLayersError.cancelled))
                }
            } catch {
                // Handle any errors
                await MainActor.run {
                    completion(.failure(error))
                }
            }
            
            // Clear the task reference
            await MainActor.run {
                self.currentExportTask = nil
            }
        }
    }
    
    // MARK: - Cancellation
    
    @MainActor
    func cancelExport() {
        currentExportTask?.cancel()
        currentExportVideoLayerTask?.cancel()
        currentExportBlackVideoLayerTask?.cancel()
        currentExportVideoTextLayerTask?.cancel()
        currentExportTask = nil
        
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTemporaryFiles(_ urls: [URL?]) {
        for url in urls {
            if let url = url {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
       
    
    
}
//MARK: - Compose Layers Extention
extension VideoExportManager {
        
    func composeFinalVideoLayers(
        videoURL: URL,
        audioURL: URL?, // Now optional
        videoTrackAudio: URL?,
        outputName: String,
        outputFormat: AVFileType,
        outputDirectory: URL
    ) async throws -> URL {
        let options: [String: Any] = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        
        let videoAsset = AVURLAsset(url: videoURL, options: options)
        
        let firstVideoAssetTrack = try await videoAsset.loadTracks(withMediaType: .video).first
        
        guard let firstVideoAssetTrack else {
            throw MediaComposeError.noVideoInVideoURL
        }
        
        let videoTimeRange = CMTimeRange(start: .zero, duration: try await videoAsset.load(.duration))
        
        let composition = AVMutableComposition()
        
        // Add video track
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 0) else {
            throw MediaComposeError.couldNotCreateVideoTrack
        }
        
        try videoTrack.insertTimeRange(videoTimeRange, of: firstVideoAssetTrack, at: .zero)
        
        var nextTrackID: CMPersistentTrackID = 1
        
        // Add first audio track if audioURL is provided
        if let audioURL {
            let audioAsset = AVURLAsset(url: audioURL, options: options)
            
            if let firstAudioAssetTrack = try await audioAsset.loadTracks(withMediaType: .audio).first {
                let audioTimeRange = CMTimeRange(start: .zero, duration: try await audioAsset.load(.duration))
                
                guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: nextTrackID) else {
                    throw MediaComposeError.couldNotCreateAudioTrack
                }
                
                try audioTrack.insertTimeRange(audioTimeRange, of: firstAudioAssetTrack, at: .zero)
                nextTrackID += 1
            }
            // If the audio URL has no audio track, we skip it (no error thrown)
        }
        
        // Add second audio track from video if provided
        if let videoTrackAudioURL = videoTrackAudio {
            let videoTrackAudioAsset = AVURLAsset(url: videoTrackAudioURL, options: options)
            
            if let secondAudioAssetTrack = try await videoTrackAudioAsset.loadTracks(withMediaType: .audio).first {
                let secondAudioTimeRange = CMTimeRange(start: .zero, duration: try await videoTrackAudioAsset.load(.duration))
                
                guard let secondAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: nextTrackID) else {
                    throw MediaComposeError.couldNotCreateAudioTrack
                }
                
                try secondAudioTrack.insertTimeRange(secondAudioTimeRange, of: secondAudioAssetTrack, at: .zero)
            }
            // If the video has no audio track, we simply skip it (no error thrown)
        }
        
        guard let asset = composition.copy() as? AVAsset else {
            throw MediaComposeError.couldNotCreateAVAssetFromComposition
        }
        
        let outputURL = outputDirectory.appending(component: outputName).appendingPathExtension(outputFormat.fileExtension)
        try? FileManager.default.removeItem(at: outputURL)
        
        try await export(asset: asset, outputFileType: outputFormat, to: outputURL)
        return outputURL
    }
    
    func export(asset: AVAsset, outputFileType: AVFileType, to outputURL: URL) async throws {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw MediaExportError.couldNotCreateExportSession
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType
        
        try await exportSession.export(to: outputURL, as: outputFileType)
    }
    
    
}
//MARK: - Background Layer Creator Extention
extension VideoExportManager {
   
    func exportVideoSegments(
        segments: [VideoSegment],
        fullDuration: Double,
        renderSize: CGSize,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (URL?) -> Void
    ) {
        // Ensure we have a black video available
        getBlackVideo(renderSize: renderSize) { blackVideoURL in
            guard let blackVideoURL = blackVideoURL else {
                completion(nil)
                return
            }
            
            // If no segments, just use the black video
            Task {
            if segments.isEmpty {
                self.currentExportBlackVideoLayerTask = await self.fillWithBlackVideo(
                    blackVideoURL: blackVideoURL,
                    duration: fullDuration,
                    renderSize: renderSize,
                    progressHandler: progressHandler,
                    completion: completion
                )
                return
            }
           
                // Create composition with segments and fill gaps/remaining time with black
                self.currentExportVideoLayerTask =  await self.createCompositionWithBlackFill(
                    segments: segments,
                    blackVideoURL: blackVideoURL,
                    fullDuration: fullDuration,
                    renderSize: renderSize,
                    progressHandler: progressHandler,
                    completion: completion
                )
            }
            
        }
    }
    
    // MARK: - Get or Create Black Video
    
    private func getBlackVideo(renderSize: CGSize, completion: @escaping (URL?) -> Void) {
        // Check if we already have a cached black video
        if let cachedURL = cachedBlackVideoURL,
           FileManager.default.fileExists(atPath: cachedURL.path) {
            completion(cachedURL)
            return
        }
        
        // Create new black video
        createBlackVideo(duration: blackVideoDuration, renderSize: renderSize) { url in
            if let url = url {
                self.cachedBlackVideoURL = url
            }
            completion(url)
        }
    }
    
    // MARK: - Create Composition with Black Fill
    @discardableResult
    private func createCompositionWithBlackFill(
        segments: [VideoSegment],
        blackVideoURL: URL,
        fullDuration: Double,
        renderSize: CGSize,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (URL?) -> Void
    ) async -> Task<Void, Never> {
        return Task {
            let composition = AVMutableComposition()
            var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
            var audioMixParams: [AVMutableAudioMixInputParameters] = []
            
            // Find all the gaps that need to be filled with black
            var timeRanges: [(start: Double, end: Double)] = []
            
            // Sort segments by start time
            let sortedSegments = segments.sorted { $0.timeLineStartTime < $1.timeLineStartTime }
            
            // Fill from 0 to first segment
            if let firstSegment = sortedSegments.first, firstSegment.timeLineStartTime > 0 {
                timeRanges.append((0, firstSegment.timeLineStartTime))
            }
            
            // Fill gaps between segments
            for i in 0..<sortedSegments.count - 1 {
                let currentEnd = sortedSegments[i].timeLineEndTime
                let nextStart = sortedSegments[i + 1].timeLineStartTime
                if nextStart > currentEnd {
                    timeRanges.append((currentEnd, nextStart))
                }
            }
            
            // Fill from last segment to full duration
            if let lastSegment = sortedSegments.last, lastSegment.timeLineEndTime < fullDuration {
                timeRanges.append((lastSegment.timeLineEndTime, fullDuration))
            }
            
            // If no segments at all, fill entire duration
            if sortedSegments.isEmpty {
                timeRanges.append((0, fullDuration))
            }
            
            // Check for cancellation
            if Task.isCancelled {
                completion(nil)
                return
            }
            
            // Insert black video for all gaps
            let blackAsset = AVURLAsset(url: blackVideoURL)
            guard let blackVideoTrack = try? await blackAsset.loadTracks(withMediaType: .video).first else {
                completion(nil)
                return
            }
            
            if Task.isCancelled {
                completion(nil)
                return
            }
            
            for range in timeRanges {
                if Task.isCancelled {
                    completion(nil)
                    return
                }
                
                let gapDuration = range.end - range.start
                let repetitions = Int(ceil(gapDuration / blackVideoDuration))
                
                guard let fillTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    continue
                }
                
                var currentTime = CMTime(seconds: range.start, preferredTimescale: 600)
                var remainingDuration = gapDuration
                
                for _ in 0..<repetitions {
                    let insertDuration = min(blackVideoDuration, remainingDuration)
                    let insertTime = CMTime(seconds: insertDuration, preferredTimescale: 600)
                    
                    do {
                        try fillTrack.insertTimeRange(
                            CMTimeRange(start: .zero, duration: insertTime),
                            of: blackVideoTrack,
                            at: currentTime
                        )
                        
                        currentTime = CMTimeAdd(currentTime, insertTime)
                        remainingDuration -= insertDuration
                    } catch {
                        print("Error inserting black video: \(error)")
                    }
                    
                    if remainingDuration <= 0.001 { break }
                }
                
                // Create layer instruction for black video
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: fillTrack)
                layerInstruction.setOpacity(1.0, at: CMTime(seconds: range.start, preferredTimescale: 600))
                layerInstruction.setOpacity(0.0, at: CMTime(seconds: range.end, preferredTimescale: 600))
                layerInstructions.append(layerInstruction)
            }
            
            // Process each video segment with its own track
            for segment in segments {
                if Task.isCancelled {
                    completion(nil)
                    return
                }
                
                let asset = AVURLAsset(url: segment.fileURL)
                
                guard let assetVideoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
                    continue
                }
                
                guard let videoTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    continue
                }
                
                let segmentStart = CMTime(seconds: segment.timeLineStartTime, preferredTimescale: 600)
                let videoStart = CMTime(seconds: segment.videoStartTime, preferredTimescale: 600)
                
                // Calculate repetitions
                let availableVideoDuration = segment.videoDuration
                let neededDuration = segment.timeLineDuration
                let repetitions = Int(ceil(neededDuration / availableVideoDuration))
                
                var currentTime = segmentStart
                var remainingDuration = neededDuration
                
                for _ in 0..<repetitions {
                    let insertDuration = min(availableVideoDuration, remainingDuration)
                    let insertTime = CMTime(seconds: insertDuration, preferredTimescale: 600)
                    
                    do {
                        try videoTrack.insertTimeRange(
                            CMTimeRange(start: videoStart, duration: insertTime),
                            of: assetVideoTrack,
                            at: currentTime
                        )
                        
                        currentTime = CMTimeAdd(currentTime, insertTime)
                        remainingDuration -= insertDuration
                    } catch {
                        print("Error inserting video: \(error)")
                    }
                    
                    if remainingDuration <= 0.001 { break }
                }
                
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                guard let assetSize = try? await assetVideoTrack.load(.naturalSize) ,
                      let assetTransform = try? await assetVideoTrack.load(.preferredTransform)
                else {
                    continue
                }
                
                let transform = calculateTransform(
                    assetSize: assetSize,
                    renderSize: renderSize,
                    assetTransform: assetTransform
                )
                layerInstruction.setTransform(transform, at: segmentStart)
                layerInstruction.setOpacity(1.0, at: segmentStart)
                layerInstruction.setOpacity(0.0, at: CMTime(seconds: segment.timeLineEndTime, preferredTimescale: 600))
                layerInstructions.append(layerInstruction)
                
                // Handle audio
                if let assetAudioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                    guard let audioTrack = composition.addMutableTrack(
                        withMediaType: .audio,
                        preferredTrackID: kCMPersistentTrackID_Invalid
                    ) else {
                        continue
                    }
                    
                    var audioCurrentTime = segmentStart
                    var audioRemainingDuration = neededDuration
                    
                    for _ in 0..<repetitions {
                        let insertDuration = min(availableVideoDuration, audioRemainingDuration)
                        let insertTime = CMTime(seconds: insertDuration, preferredTimescale: 600)
                        
                        do {
                            try audioTrack.insertTimeRange(
                                CMTimeRange(start: videoStart, duration: insertTime),
                                of: assetAudioTrack,
                                at: audioCurrentTime
                            )
                            
                            audioCurrentTime = CMTimeAdd(audioCurrentTime, insertTime)
                            audioRemainingDuration -= insertDuration
                        } catch {
                            print("Error inserting audio: \(error)")
                        }
                        
                        if audioRemainingDuration <= 0.001 { break }
                    }
                    
                    let audioParams = AVMutableAudioMixInputParameters(track: audioTrack)
                    audioParams.setVolume(segment.actualVolume, at: segmentStart)
                    audioMixParams.append(audioParams)
                }
            }
            
            if Task.isCancelled {
                completion(nil)
                return
            }
            
            // Create video composition
            let totalDuration = CMTime(seconds: fullDuration, preferredTimescale: 600)
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRange(start: .zero, duration: totalDuration)
            mainInstruction.layerInstructions = layerInstructions
            
            let videoComposition = AVMutableVideoComposition()
            videoComposition.instructions = [mainInstruction]
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.renderSize = renderSize
            
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = audioMixParams
            
            // Export
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("VideoLayerComposition")
                .appendingPathExtension("mp4")
            try? FileManager.default.removeItem(at: outputURL)
            
            guard let exporter = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality
            ) else {
                completion(nil)
                return
            }
            
            exporter.outputURL = outputURL
            exporter.outputFileType = .mp4
            exporter.videoComposition = videoComposition
            exporter.audioMix = audioMix
            
            // Use modern async export API (iOS 18+)
            if #available(iOS 18.0, *) {
                // Start monitoring progress
                let progressTask = Task {
                    do {
                        for try await state in exporter.states(updateInterval: 0.1) {
                            if Task.isCancelled {
                                break
                            }
                            
                            switch state {
                            case .exporting(let progress):
                                await MainActor.run {
                                    progressHandler(progress.fractionCompleted)
                                }
                            case .pending, .waiting:
                                break
                            @unknown default:
                                break
                            }
                        }
                    }
                }
                
                // Wait for export to complete using the new API
                do {
                    try await exporter.export(to: outputURL, as: .mp4)
                    
                    if Task.isCancelled {
                        progressTask.cancel()
                        try? FileManager.default.removeItem(at: outputURL)
                        completion(nil)
                        return
                    }
                    
                    progressTask.cancel()
                    await MainActor.run {
                        progressHandler(1.0)
                        completion(outputURL)
                    }
                } catch {
                    progressTask.cancel()
                    
                    if Task.isCancelled {
                        try? FileManager.default.removeItem(at: outputURL)
                    }
                    
                    await MainActor.run {
                        print("Export failed: \(error)")
                        completion(nil)
                    }
                }
            } else {
                // Fallback for iOS 17 and earlier
                nonisolated(unsafe) let localExporter = exporter
                
                // Monitor progress in separate task
                let progressTask = Task {
                    while !Task.isCancelled {
                        // No sleep - check continuously
                        if Task.isCancelled {
                            localExporter.cancelExport()
                            break
                        }
                        
                        let progress = localExporter.progress
                        await MainActor.run {
                            progressHandler(Double(progress))
                        }
                    }
                }
                
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    localExporter.exportAsynchronously {
                        progressTask.cancel()
                        
                        if Task.isCancelled {
                            try? FileManager.default.removeItem(at: outputURL)
                            completion(nil)
                            continuation.resume()
                            return
                        }
                        
                        switch localExporter.status {
                        case .completed:
                            progressHandler(1.0)
                            completion(outputURL)
                        case .failed, .cancelled:
                            print("Export failed")
                            completion(nil)
                        default:
                            completion(nil)
                        }
                        
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // MARK: - Fill with Black Video Only
    private func fillWithBlackVideo(
        blackVideoURL: URL,
        duration: Double,
        renderSize: CGSize,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (URL?) -> Void
    ) async -> Task<Void, Never>{
        return Task {
            let composition = AVMutableComposition()
            let blackAsset = AVURLAsset(url: blackVideoURL)
            
            guard let blackVideoTrack = try? await blackAsset.loadTracks(withMediaType: .video).first,
                  let compositionTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                  ) else {
                completion(nil)
                return
            }
            
            let repetitions = Int(ceil(duration / blackVideoDuration))
            var currentTime = CMTime.zero
            var remainingDuration = duration
            
            for _ in 0..<repetitions {
                let insertDuration = min(blackVideoDuration, remainingDuration)
                let insertTime = CMTime(seconds: insertDuration, preferredTimescale: 600)
                
                do {
                    try compositionTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: insertTime),
                        of: blackVideoTrack,
                        at: currentTime
                    )
                    
                    currentTime = CMTimeAdd(currentTime, insertTime)
                    remainingDuration -= insertDuration
                } catch {
                    print("Error inserting black video: \(error)")
                    completion(nil)
                    return
                }
                
                if remainingDuration <= 0.001 { break }
            }
            
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("BlackVideoLayerComposition")
                .appendingPathExtension("mp4")
            try? FileManager.default.removeItem(at: outputURL)
            
            guard let exporter = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality
            ) else {
                completion(nil)
                return
            }
            
            exporter.outputURL = outputURL
            exporter.outputFileType = .mp4
            
            // Use modern async export API (iOS 18+)
            if #available(iOS 18.0, *) {
                // Start monitoring progress
                let progressTask = Task {
                    do {
                        for try await state in exporter.states(updateInterval: 0.1) {
                            switch state {
                            case .exporting(let progress):
                                await MainActor.run {
                                    progressHandler(progress.fractionCompleted)
                                }
                            case .pending, .waiting:
                                break
                            @unknown default:
                                break
                            }
                        }
                    }
                }
                
                // Wait for export to complete
                do {
                    try await exporter.export(to: outputURL, as: .mp4)
                    progressTask.cancel()
                    await MainActor.run {
                        progressHandler(1.0)
                        completion(outputURL)
                    }
                } catch {
                    progressTask.cancel()
                    await MainActor.run {
                        print("Export failed: \(error)")
                        completion(nil)
                    }
                }
            } else {
                // Fallback for iOS 17 and earlier
                nonisolated(unsafe) let localExporter = exporter
                
                // Monitor progress in separate task
                let progressTask = Task {
                    while !Task.isCancelled {
                        await Task.yield() // Fast updates without excessive CPU
                        
                        let progress = localExporter.progress
                        await MainActor.run {
                            progressHandler(Double(progress))
                        }
                    }
                }
                
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    localExporter.exportAsynchronously {
                        progressTask.cancel()
                        
                        switch localExporter.status {
                        case .completed:
                            progressHandler(1.0)
                            completion(outputURL)
                        case .failed, .cancelled:
                            print("Export failed")
                            completion(nil)
                        default:
                            completion(nil)
                        }
                        
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // MARK: - Create Black Video (One Time)
    
    private func createBlackVideo(
        duration: Double,
        renderSize: CGSize,
        completion: @escaping (URL?) -> Void
    ) {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("black_video_\(Int(renderSize.width))x\(Int(renderSize.height)).mp4")
        
        // If already exists, use it
        if FileManager.default.fileExists(atPath: outputURL.path) {
            completion(outputURL)
            return
        }
        
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(nil)
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: renderSize.width,
            AVVideoHeightKey: renderSize.height
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: renderSize.width,
                kCVPixelBufferHeightKey as String: renderSize.height
            ]
        )
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let fps: Int32 = 30
        let totalFrames = Int(duration * Double(fps))
        var frameCount = 0
        
        writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "blackVideoQueue")) {
            while writerInput.isReadyForMoreMediaData && frameCount < totalFrames {
                let presentationTime = CMTime(value: Int64(frameCount), timescale: fps)
                
                if let pixelBuffer = self.createBlackPixelBuffer(size: renderSize) {
                    adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    frameCount += 1
                }
            }
            
            if frameCount >= totalFrames {
                writerInput.markAsFinished()
                writer.finishWriting {
                    if writer.status == .completed {
                        completion(outputURL)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    private func createBlackPixelBuffer(size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            options as CFDictionary,
            &pixelBuffer
        )
        
        guard let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        memset(pixelData, 0, bytesPerRow * height)
        
        return buffer
    }
    
    // MARK: - Helper Functions
    private func calculateTransform(
        assetSize: CGSize,
        renderSize: CGSize,
        assetTransform: CGAffineTransform,
        scaleMode: ScaleMode = .aspectFit,
        allowUpscaling: Bool = true
    ) -> CGAffineTransform {
        
        // Get the actual visible bounds after applying the asset's natural transform (handles rotation)
        let transformedRect = CGRect(origin: .zero, size: assetSize).applying(assetTransform)
        let videoWidth = abs(transformedRect.width)
        let videoHeight = abs(transformedRect.height)
        
        // Calculate scale based on aspect ratio
        let scaleX = renderSize.width / videoWidth
        let scaleY = renderSize.height / videoHeight
        
        var scale: CGFloat
        switch scaleMode {
        case .aspectFit:
            scale = min(scaleX, scaleY)
        case .aspectFill:
            scale = max(scaleX, scaleY)
        case .stretch:
            // For stretch, we handle it differently below
            scale = 1.0
        }
        
        // Optionally prevent upscaling
        if !allowUpscaling {
            scale = min(scale, 1.0)
        }
        
        // Build the final transform
        if scaleMode == .stretch {
            // Non-uniform scaling
            let stretchTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            
            // First apply asset transform, then stretch, then center
            let combined = assetTransform.concatenating(stretchTransform)
            let finalRect = CGRect(origin: .zero, size: assetSize).applying(combined)
            
            let translateX = (renderSize.width - finalRect.width) / 2 - finalRect.origin.x
            let translateY = (renderSize.height - finalRect.height) / 2 - finalRect.origin.y
            
            return combined.concatenating(CGAffineTransform(translationX: translateX, y: translateY))
        }
        
        // Uniform scaling: scale the asset transform components
        let scaledTransform = CGAffineTransform(
            a: assetTransform.a * scale,
            b: assetTransform.b * scale,
            c: assetTransform.c * scale,
            d: assetTransform.d * scale,
            tx: 0,
            ty: 0
        )
        
        // Calculate where the video lands after scaling
        let scaledRect = CGRect(origin: .zero, size: assetSize).applying(scaledTransform)
        
        // Center it in the render size
        let translateX = (renderSize.width - scaledRect.width) / 2 - scaledRect.origin.x
        let translateY = (renderSize.height - scaledRect.height) / 2 - scaledRect.origin.y
        
        return scaledTransform.concatenating(CGAffineTransform(translationX: translateX, y: translateY))
    }
    
    enum ScaleMode {
        case aspectFit   // Fit entire video, preserves aspect ratio
        case aspectFill  // Fill render size, may crop, preserves aspect ratio
        case stretch     // Exact fit, may distort aspect ratio
    }
//    private func calculateTransform(
//        assetSize: CGSize,
//        renderSize: CGSize,
//        assetTransform: CGAffineTransform
//    ) -> CGAffineTransform {
//        let videoRect = CGRect(origin: .zero, size: assetSize).applying(assetTransform)
//        let videoWidth = abs(videoRect.width)
//        let videoHeight = abs(videoRect.height)
//        
//        let scaleX = renderSize.width / videoWidth
//        let scaleY = renderSize.height / videoHeight
//        let scale = min(min(scaleX, scaleY), 1.0)
//        
//        let scaledWidth = videoWidth * scale
//        let scaledHeight = videoHeight * scale
//        let translateX = (renderSize.width - scaledWidth) / 2
//        let translateY = (renderSize.height - scaledHeight) / 2
//        
//        let tx = translateX + (assetTransform.tx * scale)
//        let ty = translateY + (assetTransform.ty * scale)
//        
//        return CGAffineTransform(
//            a: assetTransform.a * scale,
//            b: assetTransform.b * scale,
//            c: assetTransform.c * scale,
//            d: assetTransform.d * scale,
//            tx: tx,
//            ty: ty
//        )
//    }
    
}

//MARK: - Export Text Layer Optimized Extention
extension VideoExportManager {
    
    // Add a cancellable class
    class TextOverlayCancellable {
        private var processingTask: Task<Void, Never>?
        private var shouldCancel = false
        
        func cancel() {
            shouldCancel = true
            processingTask?.cancel()
        }
        
        fileprivate func setTask(_ task: Task<Void, Never>) {
            self.processingTask = task
        }
        
        fileprivate func isCancelled() -> Bool {
            return shouldCancel || Task.isCancelled
        }
    }
    
    @discardableResult
    func addTextOverlayToVideo(
        videoURL: URL,
        textSegments: [[TextSegment]],
        renderSize: CGSize,
        previewSize: CGSize,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (URL?) -> Void
    ) -> TextOverlayCancellable {
        let cancellable = TextOverlayCancellable()
        
        let flattenedSegments = textSegments.flatMap { $0 }
        
        guard !flattenedSegments.isEmpty else {
            completion(videoURL)
            return cancellable
        }
        
        // Pre-render text images on main thread
        let mainTask = Task { @MainActor in
            var textImages: [RenderedText] = []
            for segment in flattenedSegments {
                if cancellable.isCancelled() {
                    completion(nil)
                    return
                }
                
                if let rendered = renderTextToImage(segment: segment, renderSize: renderSize, previewSize: previewSize) {
                    textImages.append(rendered)
                }
            }
            
            // Process video on background thread
            let detachedTask = Task.detached {
                await self.processVideoWithText(
                    videoURL: videoURL,
                    textImages: textImages,
                    renderSize: renderSize,
                    previewSize: previewSize,
                    cancellable: cancellable,
                    progressHandler: progressHandler,
                    completion: completion
                )
            }
            
            cancellable.setTask(detachedTask)
        }
        
        cancellable.setTask(mainTask)
        return cancellable
    }
    
    struct RenderedText: Sendable {
        let imageData: Data
        let startTime: Double
        let endTime: Double
        let position: CGPoint
        let transitionType: TextTransitionType
        let actualOpacity: CGFloat
        let width: CGFloat
        let height: CGFloat
    }
    
    // MARK: - Render Text to Image
    
    @MainActor
    private func renderTextToImage(segment: TextSegment, renderSize: CGSize, previewSize: CGSize) -> RenderedText? {
        let scaleX = renderSize.width / previewSize.width
        let scaleY = renderSize.height / previewSize.height
        let avgScale = (scaleX + scaleY) / 2.0
        
        var scaled = segment
        scaled.fontSize = segment.fontSize * avgScale
        
        if var shadow = scaled.shadow {
            shadow.radius = shadow.radius * avgScale
            shadow.offset = shadow.offset * avgScale
            scaled.shadow = shadow
        }
        
        // Scale text wrapping if present
        if var wrapping = scaled.textWrapping {
            wrapping.thickness = wrapping.thickness * avgScale
            scaled.textWrapping = wrapping
        }
        
        let textView = Text(scaled.content)
            .lineLimit(1)
            .textSegmentStyle(segment: scaled, scale: avgScale)
            .fixedSize()
        
        let renderer = ImageRenderer(content: textView)
        renderer.scale = 1.0
        
        guard let image = renderer.uiImage,
              let imageData = image.pngData() else { return nil }
        
        return RenderedText(
            imageData: imageData,
            startTime: segment.startTime,
            endTime: segment.endTime,
            position: segment.position,
            transitionType: segment.transitionType,
            actualOpacity: segment.actualOpacity,
            width: image.size.width,
            height: image.size.height
        )
    }
    
    // MARK: - Process Video
    
    private func processVideoWithText(
        videoURL: URL,
        textImages: [RenderedText],
        renderSize: CGSize,
        previewSize: CGSize,
        cancellable: TextOverlayCancellable,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (URL?) -> Void
    ) async {
        let asset = AVURLAsset(url: videoURL)
        
        if cancellable.isCancelled() {
            await MainActor.run { completion(nil) }
            return
        }
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            await MainActor.run { completion(nil) }
            return
        }
        
        if cancellable.isCancelled() {
            await MainActor.run { completion(nil) }
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LastTextVideoLayer")
            .appendingPathExtension("mp4")
        try? FileManager.default.removeItem(at: outputURL)
        
        do {
            let reader = try AVAssetReader(asset: asset)
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            // Setup video output
            let videoOutput = AVAssetReaderTrackOutput(
                track: videoTrack,
                outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            )
            reader.add(videoOutput)
            
            // Setup video input
            let videoInput = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: renderSize.width,
                    AVVideoHeightKey: renderSize.height
                ]
            )
            videoInput.expectsMediaDataInRealTime = false
            writer.add(videoInput)
            
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: renderSize.width,
                    kCVPixelBufferHeightKey as String: renderSize.height
                ]
            )
            
            if cancellable.isCancelled() {
                await MainActor.run { completion(nil) }
                return
            }
            
            // Start reader and writer
            guard reader.startReading(), writer.startWriting() else {
                await MainActor.run { completion(nil) }
                return
            }
            
            writer.startSession(atSourceTime: .zero)
            
            // Prepare text data - convert to CIImage
            let scaleX = renderSize.width / previewSize.width
            let scaleY = renderSize.height / previewSize.height
            
            let preparedTexts: [(ciImage: CIImage, textData: RenderedText)] = textImages.compactMap { textData in
                guard let uiImage = UIImage(data: textData.imageData),
                      let cgImage = uiImage.cgImage else { return nil }
                let ciImage = CIImage(cgImage: cgImage)
                return (ciImage, textData)
            }
            
            let ciContext = CIContext(options: [
                .useSoftwareRenderer: false,
                .cacheIntermediates: false,
                .highQualityDownsample: false
            ])
            
            let fps: Double = 30
            let totalFrames = try await Int64(asset.load(.duration).seconds * fps)
            
            // Create pixel buffer pool for reuse
            var pixelBufferPool: CVPixelBufferPool?
            let poolAttributes: [CFString: Any] = [
                kCVPixelBufferPoolMinimumBufferCountKey: 6
            ]
            let pixelBufferAttributes: [CFString: Any] = [
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey: renderSize.width,
                kCVPixelBufferHeightKey: renderSize.height,
                kCVPixelBufferIOSurfacePropertiesKey: [:]
            ]
            CVPixelBufferPoolCreate(
                kCFAllocatorDefault,
                poolAttributes as CFDictionary,
                pixelBufferAttributes as CFDictionary,
                &pixelBufferPool
            )
            
            // Process frames using actor for thread-safe state management
            let frameProcessor = FrameProcessor(
                videoInput: videoInput,
                adaptor: adaptor,
                totalFrames: totalFrames,
                progressHandler: progressHandler
            )
            
            // Process frames sequentially (simpler and safer)
            var frameCount: Int64 = 0
            
            while let sampleBuffer = videoOutput.copyNextSampleBuffer() {
                // Check cancellation at each frame
                if cancellable.isCancelled() {
                    reader.cancelReading()
                    writer.cancelWriting()
                    try? FileManager.default.removeItem(at: outputURL)
                    await MainActor.run { completion(nil) }
                    return
                }
                
                autoreleasepool {
                    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                        return
                    }
                    
                    let currentFrameIndex = frameCount
                    frameCount += 1
                    
                    let currentTime = Double(currentFrameIndex) / fps
                    var ciImage = CIImage(cvPixelBuffer: imageBuffer)
                    
                    // Scale video if needed
                    let videoSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
                    if videoSize != renderSize {
                        ciImage = ciImage.transformed(by: CGAffineTransform(
                            scaleX: renderSize.width / videoSize.width,
                            y: renderSize.height / videoSize.height
                        ))
                    }
                    
                    // Add text overlays
                    for preparedText in preparedTexts {
                        let textData = preparedText.textData
                        guard currentTime >= textData.startTime && currentTime <= textData.endTime else { continue }
                        
                        let scaledPos = CGPoint(x: textData.position.x * scaleX, y: textData.position.y * scaleY)
                        let (finalPos, opacity) = self.applyTransition(
                            transitionType: textData.transitionType,
                            actualOpacity: textData.actualOpacity,
                            startTime: textData.startTime,
                            at: currentTime,
                            basePosition: scaledPos,
                            videoSize: renderSize
                        )
                        
                        var textCI = preparedText.ciImage
                        
                        if opacity < 1.0 {
                            textCI = textCI.applyingFilter("CIColorMatrix", parameters: [
                                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: opacity)
                            ])
                        }
                        
                        let imgW = textData.width
                        let imgH = textData.height
                        let topLeftX = finalPos.x - imgW / 2
                        let topLeftY = finalPos.y - imgH / 2
                        let ciX = topLeftX
                        let ciY = renderSize.height - topLeftY - imgH
                        
                        textCI = textCI.transformed(by: CGAffineTransform(translationX: ciX, y: ciY))
                        ciImage = textCI.composited(over: ciImage)
                    }
                    
                    // Render to pixel buffer
                    var pixelBuffer: CVPixelBuffer?
                    if let pool = pixelBufferPool {
                        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
                    }
                    
                    if let buffer = pixelBuffer {
                        ciContext.render(ciImage, to: buffer)
                        
                        // Wait for writer to be ready
                        while !videoInput.isReadyForMoreMediaData {
                            // Check cancellation while waiting
                            if cancellable.isCancelled() {
                                return
                            }
                            Thread.sleep(forTimeInterval: 0.002)
                        }
                        
                        let presentationTime = CMTime(seconds: Double(currentFrameIndex) / fps, preferredTimescale: 600)
                        adaptor.append(buffer, withPresentationTime: presentationTime)
                        
                        // Update progress
                        Task {
                            await frameProcessor.updateProgress(frameIndex: currentFrameIndex)
                        }
                    }
                }
            }
            
            // Final cancellation check before finishing
            if cancellable.isCancelled() {
                reader.cancelReading()
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                await MainActor.run { completion(nil) }
                return
            }
            
            videoInput.markAsFinished()
            await writer.finishWriting()
            
            let writerStatus = writer.status
            await MainActor.run {
                if writerStatus == .completed {
                    progressHandler(1.0)
                    completion(outputURL)
                } else {
                    completion(nil)
                }
            }
            
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            await MainActor.run { completion(nil) }
        }
    }
    
    // MARK: - Frame Processor Actor
    
    private actor FrameProcessor {
        let videoInput: AVAssetWriterInput
        let adaptor: AVAssetWriterInputPixelBufferAdaptor
        let totalFrames: Int64
        let progressHandler: (Double) -> Void
        
        init(videoInput: AVAssetWriterInput, adaptor: AVAssetWriterInputPixelBufferAdaptor, totalFrames: Int64, progressHandler: @escaping (Double) -> Void) {
            self.videoInput = videoInput
            self.adaptor = adaptor
            self.totalFrames = totalFrames
            self.progressHandler = progressHandler
        }
        
        func updateProgress(frameIndex: Int64) {
            if frameIndex % 30 == 0 {
                let progress = Double(frameIndex) / Double(totalFrames)
                Task { @MainActor in
                    progressHandler(progress)
                }
            }
        }
    }
    
    // MARK: - Transition Helper
    
    func applyTransition(
        transitionType: TextTransitionType,
        actualOpacity: CGFloat,
        startTime: Double,
        at currentTime: Double,
        basePosition: CGPoint,
        videoSize: CGSize
    ) -> (CGPoint, CGFloat) {
        guard transitionType != .none else {
            return (basePosition, actualOpacity)
        }
        
        let duration: Double = transitionType == .fade ? 1.5 : 0.5
        let elapsed = currentTime - startTime
        let progress = max(0, min(elapsed / duration, 1.0))
        
        if transitionType == .fade {
            return (basePosition, progress * actualOpacity)
        }
        
        let offset: CGPoint = {
            switch transitionType {
            case .enterFromLeft: return CGPoint(x: 0, y: basePosition.y)
            case .enterFromRight: return CGPoint(x: videoSize.width, y: basePosition.y)
            case .enterFromTop: return CGPoint(x: basePosition.x, y: 0)
            case .enterFromBottom: return CGPoint(x: basePosition.x, y: videoSize.height)
            case .enterFromTopLeft: return CGPoint(x: 0, y: 0)
            case .enterFromTopRight: return CGPoint(x: videoSize.width, y: 0)
            case .enterFromBottomLeft: return CGPoint(x: 0, y: videoSize.height)
            case .enterFromBottomRight: return CGPoint(x: videoSize.width, y: videoSize.height)
            default: return basePosition
            }
        }()
        
        return (
            CGPoint(
                x: offset.x + (basePosition.x - offset.x) * progress,
                y: offset.y + (basePosition.y - offset.y) * progress
            ),
            actualOpacity
        )
    }
}

//MARK: - Export Audio Track Extenstion
extension VideoExportManager {

    func mixAudioSegments(audioSegments : [AudioSegment]) async -> URL? {
        let composition = AVMutableComposition()
        var audioMixParams: [AVAudioMixInputParameters] = []
        
        for segment in audioSegments {
            let asset = AVURLAsset(url: segment.fileURL)
            guard let sourceTrack = try? await asset.loadTracks(withMediaType: .audio).first else { continue }
            
            let startTime = CMTime(seconds: segment.audioStartTime, preferredTimescale: 600)
            let duration = CMTime(seconds: segment.audioDuration, preferredTimescale: 600)
            let timelineStart = CMTime(seconds: segment.timeLineStartTime, preferredTimescale: 600)
            
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            
            do {
                try audioTrack.insertTimeRange(CMTimeRange(start: startTime, duration: duration), of: sourceTrack, at: timelineStart)
            } catch {
                print("❌ Failed to insert audio segment: \(error)")
                continue
            }
            
            let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
            
            if segment.fadeInDuration > 0 {
                inputParams.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: segment.actualVolume, timeRange: CMTimeRange(start: timelineStart, duration: CMTime(seconds: segment.fadeInDuration, preferredTimescale: 600)))
            } else {
                inputParams.setVolume(segment.actualVolume, at: timelineStart)
            }
            
            if segment.fadeOutDuration > 0 {
                let fadeOutStart = timelineStart + CMTime(seconds: segment.timeLineDuration - segment.fadeOutDuration, preferredTimescale: 600)
                inputParams.setVolumeRamp(fromStartVolume: segment.actualVolume, toEndVolume: 0.0, timeRange: CMTimeRange(start: fadeOutStart, duration: CMTime(seconds: segment.fadeOutDuration, preferredTimescale: 600)))
            }
            
            audioMixParams.append(inputParams)
        }
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioMixParams
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("mixed_audio.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            return nil
        }
        
        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a
        exporter.audioMix = audioMix
        let totalAudioDuration = audioSegments.map { $0.timeLineEndTime }.max() ?? 0
        exporter.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: totalAudioDuration, preferredTimescale: 600))
        
        do {
            try await exporter.export(to: outputURL, as: .m4a)
            return outputURL
        } catch {
            print("❌ Export failed: \(error.localizedDescription)")
            return nil
        }
    }
}


//MARK: - Export text old way ( work fine )
//extension VideoExportManager{
//
//    func addTextOverlayToVideo(
//        videoURL: URL,
//        textSegments: [[TextSegment]],
//        renderSize: CGSize,
//        previewSize: CGSize,
//        progressHandler: @escaping (Double) -> Void,
//        completion: @escaping (URL?) -> Void
//    ) {
//        let flattenedSegments = textSegments.flatMap { $0 }
//        
//        guard !flattenedSegments.isEmpty else {
//            completion(videoURL)
//            return
//        }
//        
//        // Pre-render text images on main thread
//        Task { @MainActor in
//            var textImages: [RenderedText] = []
//            for segment in flattenedSegments {
//                if let rendered = renderTextToImage(segment: segment, renderSize: renderSize, previewSize: previewSize) {
//                    textImages.append(rendered)
//                }
//            }
//            
//            // Process video on background thread
//            Task.detached {
//                await self.processVideoWithText(
//                    videoURL: videoURL,
//                    textImages: textImages,
//                    renderSize: renderSize,
//                    previewSize: previewSize,
//                    progressHandler: progressHandler,
//                    completion: completion
//                )
//            }
//        }
//    }
//    
//    struct RenderedText {
//        let image: UIImage
//        let segment: TextSegment
//    }
//    
//    // MARK: - Render Text to Image
//    
//    
//    @MainActor
//        private func renderTextToImage(segment: TextSegment, renderSize: CGSize, previewSize: CGSize) -> RenderedText? {
//            let scaleX = renderSize.width / previewSize.width
//            let scaleY = renderSize.height / previewSize.height
//            let avgScale = (scaleX + scaleY) / 2.0
//    
//            var scaled = segment
//            scaled.fontSize = segment.fontSize * avgScale
//    
//            if var shadow = scaled.shadow {
//                shadow.radius = shadow.radius * avgScale
//                shadow.offset = shadow.offset * avgScale
//                scaled.shadow = shadow
//            }
//    
//            // Scale text wrapping if present
//            if var wrapping = scaled.textWrapping {
//                wrapping.thickness = wrapping.thickness * avgScale
//                scaled.textWrapping = wrapping
//            }
//    
//            let textView = Text(scaled.content)
//                .lineLimit(1)
//                .textSegmentStyle(segment: scaled,scale: avgScale)
//                .fixedSize()
//    
//            let renderer = ImageRenderer(content: textView)
//            renderer.scale = 1.0
//    
//            guard let image = renderer.uiImage else { return nil }
//    
//            return RenderedText(image: image, segment: segment)
//        }
//    // MARK: - Process Video
//    
//    private func processVideoWithText(
//        videoURL: URL,
//        textImages: [RenderedText],
//        renderSize: CGSize,
//        previewSize: CGSize,
//        progressHandler: @escaping (Double) -> Void,
//        completion: @escaping (URL?) -> Void
//    ) async {
//        let asset = AVURLAsset(url: videoURL)
//        
//        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
//            await MainActor.run { completion(nil) }
//            return
//        }
//        
//        let outputURL = FileManager.default.temporaryDirectory
//            .appendingPathComponent(UUID().uuidString)
//            .appendingPathExtension("mp4")
//        
//        do {
//            let reader = try AVAssetReader(asset: asset)
//            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
//            
//            // Setup video output
//            let videoOutput = AVAssetReaderTrackOutput(
//                track: videoTrack,
//                outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
//            )
//            reader.add(videoOutput)
//            
//            // Setup video input
//            let videoInput = AVAssetWriterInput(
//                mediaType: .video,
//                outputSettings: [
//                    AVVideoCodecKey: AVVideoCodecType.h264,
//                    AVVideoWidthKey: renderSize.width,
//                    AVVideoHeightKey: renderSize.height
//                ]
//            )
//            videoInput.expectsMediaDataInRealTime = false
//            writer.add(videoInput)
//            
//            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
//                assetWriterInput: videoInput,
//                sourcePixelBufferAttributes: [
//                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
//                    kCVPixelBufferWidthKey as String: renderSize.width,
//                    kCVPixelBufferHeightKey as String: renderSize.height
//                ]
//            )
//            
//            // Start reader and writer
//            guard reader.startReading(), writer.startWriting() else {
//                await MainActor.run { completion(nil) }
//                return
//            }
//            
//            writer.startSession(atSourceTime: .zero)
//            
//            // Prepare text data - pre-convert to CIImage (only once)
//            let scaleX = renderSize.width / previewSize.width
//            let scaleY = renderSize.height / previewSize.height
//            
//            let preparedTexts: [(ciImage: CIImage, segment: TextSegment, width: CGFloat, height: CGFloat)] = textImages.map { textData in
//                let ciImage = CIImage(cgImage: textData.image.cgImage!)
//                return (ciImage, textData.segment, textData.image.size.width, textData.image.size.height)
//            }
//            
//            let ciContext = CIContext(options: [
//                .useSoftwareRenderer: false,
//                .cacheIntermediates: false,
//                .highQualityDownsample: false
//            ])
//            
//            let fps: Double = 30
//            var frameCount: Int64 = 0
//            let totalFrames = Int64(asset.duration.seconds * fps)
//            
//            // Create pixel buffer pool for reuse
//            var pixelBufferPool: CVPixelBufferPool?
//            let poolAttributes: [CFString: Any] = [
//                kCVPixelBufferPoolMinimumBufferCountKey: 3
//            ]
//            let pixelBufferAttributes: [CFString: Any] = [
//                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
//                kCVPixelBufferWidthKey: renderSize.width,
//                kCVPixelBufferHeightKey: renderSize.height,
//                kCVPixelBufferIOSurfacePropertiesKey: [:]
//            ]
//            CVPixelBufferPoolCreate(
//                kCFAllocatorDefault,
//                poolAttributes as CFDictionary,
//                pixelBufferAttributes as CFDictionary,
//                &pixelBufferPool
//            )
//            
//            // Process frames
//            while let sampleBuffer = videoOutput.copyNextSampleBuffer() {
//                autoreleasepool {
//                    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//                    
//                    let currentTime = Double(frameCount) / fps
//                    var ciImage = CIImage(cvPixelBuffer: imageBuffer)
//                    
//                    // Scale video if needed (only once per video, not per frame)
//                    let videoSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
//                    if videoSize != renderSize {
//                        ciImage = ciImage.transformed(by: CGAffineTransform(
//                            scaleX: renderSize.width / videoSize.width,
//                            y: renderSize.height / videoSize.height
//                        ))
//                    }
//                    
//                    // Add text overlays (use pre-converted CIImages)
//                    for textData in preparedTexts {
//                        let seg = textData.segment
//                        
//                        guard currentTime >= seg.startTime && currentTime <= seg.endTime else { continue }
//                        
//                        let scaledPos = CGPoint(x: seg.position.x * scaleX, y: seg.position.y * scaleY)
//                        let (finalPos, opacity) = applyTransition(to: seg, at: currentTime, basePosition: scaledPos, videoSize: renderSize)
//                        
//                        var textCI = textData.ciImage
//                        
//                        if opacity < 1.0 {
//                            textCI = textCI.applyingFilter("CIColorMatrix", parameters: [
//                                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: opacity)
//                            ])
//                        }
//                        
//                        let imgW = textData.width
//                        let imgH = textData.height
//                        
//                        let topLeftX = finalPos.x - imgW / 2
//                        let topLeftY = finalPos.y - imgH / 2
//                        
//                        let ciX = topLeftX
//                        let ciY = renderSize.height - topLeftY - imgH
//                        
//                        textCI = textCI.transformed(by: CGAffineTransform(translationX: ciX, y: ciY))
//                        ciImage = textCI.composited(over: ciImage)
//                    }
//                    
//                    // Write frame using pixel buffer pool
//                    var pixelBuffer: CVPixelBuffer?
//                    if let pool = pixelBufferPool {
//                        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
//                    } else {
//                        CVPixelBufferCreate(
//                            kCFAllocatorDefault,
//                            Int(renderSize.width),
//                            Int(renderSize.height),
//                            kCVPixelFormatType_32BGRA,
//                            nil,
//                            &pixelBuffer
//                        )
//                    }
//                    
//                    if let buffer = pixelBuffer {
//                        ciContext.render(ciImage, to: buffer)
//                        
//                        while !videoInput.isReadyForMoreMediaData {
//                            Thread.sleep(forTimeInterval: 0.005) // Reduced from 0.01
//                        }
//                        
//                        adaptor.append(buffer, withPresentationTime: CMTime(seconds: currentTime, preferredTimescale: 600))
//                    }
//                    
//                    frameCount += 1
//                    if frameCount % 30 == 0 {
//                        let progress = Double(frameCount) / Double(totalFrames)
//                        Task { @MainActor in progressHandler(progress) }
//                    }
//                }
//            }
//            
//            videoInput.markAsFinished()
//            await writer.finishWriting()
//            
//            await MainActor.run {
//                if writer.status == .completed {
//                    progressHandler(1.0)
//                    completion(outputURL)
//                } else {
//                    completion(nil)
//                }
//            }
//            
//        } catch {
//            await MainActor.run { completion(nil) }
//        }
//    }
//    
//    // MARK: - Transition Helper
//    
//    func applyTransition(to segment: TextSegment, at currentTime: Double, basePosition: CGPoint, videoSize: CGSize) -> (CGPoint, CGFloat) {
//        guard segment.transitionType != .none else {
//            return (basePosition, segment.actualOpacity)
//        }
//        
//        let duration: Double = segment.transitionType == .fade ? 1.5 : 0.5
//        let elapsed = currentTime - segment.startTime
//        let progress = max(0, min(elapsed / duration, 1.0))
//        
//        if segment.transitionType == .fade {
//            return (basePosition, progress * segment.actualOpacity)
//        }
//        
//        let offset: CGPoint = {
//            switch segment.transitionType {
//            case .enterFromLeft: return CGPoint(x: 0, y: basePosition.y)
//            case .enterFromRight: return CGPoint(x: videoSize.width, y: basePosition.y)
//            case .enterFromTop: return CGPoint(x: basePosition.x, y: 0)
//            case .enterFromBottom: return CGPoint(x: basePosition.x, y: videoSize.height)
//            case .enterFromTopLeft: return CGPoint(x: 0, y: 0)
//            case .enterFromTopRight: return CGPoint(x: videoSize.width, y: 0)
//            case .enterFromBottomLeft: return CGPoint(x: 0, y: videoSize.height)
//            case .enterFromBottomRight: return CGPoint(x: videoSize.width, y: videoSize.height)
//            default: return basePosition
//            }
//        }()
//        
//        return (
//            CGPoint(
//                x: offset.x + (basePosition.x - offset.x) * progress,
//                y: offset.y + (basePosition.y - offset.y) * progress
//            ),
//            segment.actualOpacity
//        )
//    }
//}


extension UIImage {
    func pixelBuffer(size: CGSize) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &buffer
        )
        guard let context = buffer else { return nil }

        CVPixelBufferLockBaseAddress(context, [])
        let data = CVPixelBufferGetBaseAddress(context)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: data,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(context),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        UIGraphicsPushContext(ctx)
        self.draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(context, [])
        return context
    }
    
}
extension AVFileType {
    var fileExtension: String {
        guard let type = UTType(self.rawValue),
              let preferredFilenameExtension = type.preferredFilenameExtension
        else {
            return ""
        }
        return preferredFilenameExtension
    }
}
