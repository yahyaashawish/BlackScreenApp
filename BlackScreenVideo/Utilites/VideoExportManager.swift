import Foundation
import AVFoundation
import UIKit
enum MediaExportError: Error {
    case couldNotCreateExportSession
}

enum MediaComposeError: Error {
    case noVideoInVideoURL
    case noAudioInAudioURL
    case couldNotCreateVideoTrack
    case couldNotCreateAudioTrack
    case couldNotCreateAVAssetFromComposition
}

public class VideoExportManager{
    let videoSize: CGSize
    let previewSize : CGSize
    let fps: Int32 = 30
    var videoWriter: AVAssetWriter? = nil
    var exportingTask: Task<Void, Never>? = nil
    init(videoSize: CGSize,previewSize : CGSize) {
        self.videoSize = videoSize
        self.previewSize = previewSize
    }
    func exportVideo(textSegments : [[TextSegment]],
                     audioSegments : [AudioSegment],duration:Double,
                     progressHandler: @escaping (Double) -> Void,
                     completion: @escaping (Result<URL, Error>) -> Void)
    {
        
        exportingTask = Task{
            exportTextSegments(textSegments: textSegments,duration: duration) { progress in
                progressHandler(progress)
            } completion: { url in
                if let textsVideoUrl = url {
                    let audioMix = await self.mixAudioSegments(audioSegments: audioSegments)
                    
                    if let audioMixUrl = audioMix {
                        do {
                            let outputURL = try await self.compose(
                                videoURL: textsVideoUrl,
                                audioURL: audioMixUrl,
                                outputName: "FinalExportedVideo",
                                outputFormat: .mp4,
                                outputDirectory: FileManager.default.temporaryDirectory
                            )
                            completion(.success(outputURL))
                        }catch{
                            completion(.failure(error))
                        }
                        
                    }else{
                        completion(.failure(MediaComposeError.noAudioInAudioURL))
                    }
                }else{
                    completion(.failure(MediaComposeError.noVideoInVideoURL))
                }
            }
        }
        
        
        
    }
//    func compose(
//        videoURL: URL,
//        audioURL: URL,
//        outputName: String,
//        outputFormat: AVFileType,
//        outputDirectory: URL
//    ) async throws -> URL {
//        let options: [String: Any] = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
//        
//        let videoAsset = AVURLAsset(url: videoURL, options: options)
//        let audioAsset = AVURLAsset(url: audioURL, options: options)
//        
//        async let firstVideoAssetTrack = try await videoAsset.loadTracks(withMediaType: .video).first
//        async let firstAudioAssetTrack = try await audioAsset.loadTracks(withMediaType: .audio).first
//        
//        guard let firstVideoAssetTrack = try await firstVideoAssetTrack else {
//            throw MediaComposeError.noVideoInVideoURL
//        }
//        guard let firstAudioAssetTrack = try await firstAudioAssetTrack else {
//            throw MediaComposeError.noAudioInAudioURL
//        }
//        
//        let videoDuration = try await videoAsset.load(.duration)
//        let audioDuration = try await audioAsset.load(.duration)
//        
//        let videoTimeRange = CMTimeRange(start: .zero, duration: videoDuration)
//        let audioTimeRange = CMTimeRange(start: .zero, duration: audioDuration)
//        
//        let composition = AVMutableComposition()
//        
//        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
//              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            throw MediaComposeError.couldNotCreateVideoTrack
//        }
//        
//        try videoTrack.insertTimeRange(videoTimeRange, of: firstVideoAssetTrack, at: .zero)
//        try audioTrack.insertTimeRange(audioTimeRange, of: firstAudioAssetTrack, at: .zero)
//        
//        // ✅ Freeze last video frame using video composition
//        let instruction = AVMutableVideoCompositionInstruction()
//        instruction.timeRange = CMTimeRange(start: .zero, duration: audioDuration)
//        
//        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
//        let transform = try await firstVideoAssetTrack.load(.preferredTransform)
//        
//        // Apply the transform and freeze the last frame
//        layerInstruction.setTransform(transform, at: .zero)
//        layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 1.0,
//                                        timeRange: CMTimeRange(start: videoDuration,
//                                                               duration: audioDuration - videoDuration))
//        
//        instruction.layerInstructions = [layerInstruction]
//        
//        let videoComposition = AVMutableVideoComposition()
//        videoComposition.instructions = [instruction]
//        videoComposition.renderSize = try await firstVideoAssetTrack.load(.naturalSize)
//        videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 fps
//        
//        // Export final video
//        let outputURL = outputDirectory
//            .appending(component: outputName)
//            .appendingPathExtension(outputFormat.fileExtension)
//        try? FileManager.default.removeItem(at: outputURL)
//        
//        try await export(asset: composition,videoComposition: videoComposition,outputURL: outputURL, outputFileType: outputFormat)
//        
//        return outputURL
//    }

    func compose(
        videoURL: URL,
        audioURL: URL,
        outputName: String,
        outputFormat: AVFileType,
        outputDirectory: URL
    ) async throws -> URL {
        let options: [String: Any] = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        
        // 1. Get tracks
        
        let videoAsset = AVURLAsset(url: videoURL, options: options)
        let audioAsset = AVURLAsset(url: audioURL, options: options)
        
        async let firstVideoAssetTrack = try await videoAsset.loadTracks(withMediaType: .video).first
        async let firstAudioAssetTrack = try await audioAsset.loadTracks(withMediaType: .audio).first
        
        guard let firstVideoAssetTrack = try await firstVideoAssetTrack else {
            throw MediaComposeError.noVideoInVideoURL
        }
        guard let firstAudioAssetTrack = try await firstAudioAssetTrack else {
            throw MediaComposeError.noAudioInAudioURL
        }
        
        // 2. Get video time range
        
        let videoTimeRange = CMTimeRange(
            start: .zero,
            duration: try await videoAsset.load(.duration)
        )
        let audioTimeRange = CMTimeRange(
            start: .zero,
            duration: try await audioAsset.load(.duration)
        )
        
        // 3. Create composition
        
        let composition = AVMutableComposition()
        
        // 4. Add tracks
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 0) else {
            throw MediaComposeError.couldNotCreateVideoTrack
        }
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 1) else {
            throw MediaComposeError.couldNotCreateAudioTrack
        }
        
        // 5. Insert time ranges in tracks
        
        try videoTrack.insertTimeRange(videoTimeRange, of: firstVideoAssetTrack, at: .zero)
        try audioTrack.insertTimeRange(audioTimeRange, of: firstAudioAssetTrack, at: .zero)
        
        // 6. Copy composition as AVAsset
        
        guard let asset = composition.copy() as? AVAsset else {
            throw MediaComposeError.couldNotCreateAVAssetFromComposition
        }
        
        // 7. Create an output url
        
        let outputURL = outputDirectory
            .appending(component: outputName)
            .appendingPathExtension(outputFormat.fileExtension)
        try? FileManager.default.removeItem(at: outputURL)

        try await export(asset: asset, outputURL: outputURL, outputFileType: outputFormat)
        
        // 8. Return output url
        
        return outputURL
    }
    func export(
        asset: AVAsset,
        videoComposition: AVVideoComposition? = nil,
        outputURL: URL,
        outputFileType: AVFileType
    ) async throws {
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            throw MediaExportError.couldNotCreateExportSession
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType
        exportSession.videoComposition = videoComposition
        
        do {
            try await exportSession.export(to: outputURL, as: outputFileType)
        }
    }

    private func blackFrame() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: videoSize)
        return renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: videoSize))
        }
    }
    


    func exportTextSegments(
        textSegments: [[TextSegment]],
        duration: Double,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (URL?) async throws -> Void
    ) {
        let totalDuration = duration
        let totalFrames = Int(totalDuration * Double(fps))
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.mp4")
        try? FileManager.default.removeItem(at: outputURL)
        
        let writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        self.videoWriter = writer
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(videoSize.width),
            AVVideoHeightKey: Int(videoSize.height)
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        writer.add(input)
        
        let adapter = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: Int(videoSize.width),
                kCVPixelBufferHeightKey as String: Int(videoSize.height)
            ]
        )
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        DispatchQueue.global(qos: .userInitiated).async {
            while !input.isReadyForMoreMediaData {
                usleep(1000)
            }
            
            let flatSegments = textSegments.flatMap { $0 }
            let frameRate = Double(self.fps)
            let frameDuration = 1.0 / frameRate
            var currentTime: Double = 0
            var frameCount = 0
            
            input.requestMediaDataWhenReady(on: DispatchQueue(label: "renderQueue")) {
                guard let pixelBufferPool = adapter.pixelBufferPool else {
                    print("❌ Pixel buffer pool is STILL nil even after isReadyForMoreMediaData!")
                    return
                }
                let blackBuffer = self.makeBlackPixelBuffer(from: pixelBufferPool)
                guard let blackImage = blackBuffer else {
                    print("❌ Black image is nil!")
                    return
                }
                
                while input.isReadyForMoreMediaData && currentTime < totalDuration {
                    autoreleasepool {
                        let activeSegments = flatSegments.filter { segment in
                            currentTime >= segment.startTime && currentTime < segment.startTime + segment.duration
                        }
                        
                        var didRenderFrame = false
                        
                        if activeSegments.isEmpty {
                            let nextSegmentTime = flatSegments.compactMap { $0.startTime > currentTime ? $0.startTime : nil }.min()
                            let blackTime = CMTime(seconds: currentTime, preferredTimescale: CMTimeScale(600))
                            adapter.append(blackImage, withPresentationTime: blackTime)
                            frameCount += 1
                            currentTime = nextSegmentTime ?? totalDuration
                            DispatchQueue.main.async {
                                progressHandler(Double(frameCount) / Double(totalFrames))
                            }
                            didRenderFrame = true
                        }
                        
                        if !didRenderFrame {
                            let time = CMTime(seconds: currentTime, preferredTimescale: CMTimeScale(600))
                            UIGraphicsBeginImageContext(self.videoSize)
                            guard let context = UIGraphicsGetCurrentContext() else { currentTime += frameDuration; return }
                            
                            context.setFillColor(UIColor.black.cgColor)
                            context.fill(CGRect(origin: .zero, size: self.videoSize))
                            context.translateBy(x: 0, y: self.videoSize.height)
                            context.scaleBy(x: 1.0, y: -1.0)
                            
                            for segment in activeSegments {
                                let scale = min(self.previewSize.width / self.videoSize.width,
                                                self.previewSize.height / self.videoSize.height)
                                
                                let attributedText = TextSegmentContentRenderer.attributedText(from: segment, with: scale)
                                let basePosition = CGPoint(x: segment.position.x / scale, y: segment.position.y / scale)
                                
                                let (adjustedPosition, opacity) = self.applyTransition(to: segment, at: currentTime, basePosition: basePosition)
                                
                                let textSize = attributedText.size()
                                let origin = CGPoint(
                                    x: adjustedPosition.x - textSize.width / 2,
                                    y: adjustedPosition.y - textSize.height / 2
                                )
                                
                                context.saveGState()
                                context.setAlpha(opacity)
                                attributedText.draw(at: origin)
                                context.restoreGState()
                            }
                            
                            let image = UIGraphicsGetImageFromCurrentImageContext()!
                            UIGraphicsEndImageContext()
                            
                            var pixelBuffer: CVPixelBuffer?
                            let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
                            if status == kCVReturnSuccess, let buffer = pixelBuffer {
                                CVPixelBufferLockBaseAddress(buffer, [])
                                let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                                let context2 = CGContext(
                                    data: CVPixelBufferGetBaseAddress(buffer),
                                    width: Int(self.videoSize.width),
                                    height: Int(self.videoSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                    space: rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                                )
                                
                                UIGraphicsPushContext(context2!)
                                image.draw(in: CGRect(origin: .zero, size: self.videoSize))
                                UIGraphicsPopContext()
                                CVPixelBufferUnlockBaseAddress(buffer, [])
                                
                                adapter.append(buffer, withPresentationTime: time)
                                frameCount += 1
                                currentTime += frameDuration
                                DispatchQueue.main.async {
                                    progressHandler(Double(frameCount) / Double(totalFrames))
                                }
                            } else {
                                print("⚠️ Failed to create pixel buffer at time \(currentTime)")
                                currentTime += frameDuration
                            }
                        }
                        
                        if currentTime >= totalDuration {
                            input.markAsFinished()
                            writer.finishWriting {
                                Task {
                                    try? await completion(writer.status == .completed ? outputURL : nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func makeBlackPixelBuffer(from pool: CVPixelBufferPool) -> CVPixelBuffer? {
        // 1. Create black UIImage
        let blackFrame = UIGraphicsImageRenderer(size: videoSize).image { ctx in
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: videoSize))
        }
        
        // 2. Create pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("❌ Failed to create black pixel buffer")
            return nil
        }
        
        // 3. Draw black UIImage into buffer
        CVPixelBufferLockBaseAddress(buffer, [])
        if let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(videoSize.width),
            height: Int(videoSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) {
            UIGraphicsPushContext(context)
            blackFrame.draw(in: CGRect(origin: .zero, size: videoSize))
            UIGraphicsPopContext()
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }

    func applyTransition(to segment: TextSegment, at currentTime: Double, basePosition: CGPoint) -> (CGPoint, CGFloat) {
        guard  segment.transitionType != .none else {
            return (basePosition, segment.textColor.opacity)
        }
        let transition = segment.transitionType
        
        let transitionDuration: Double = transition == .fade ? 1.5 : 0.5
        let elapsed = currentTime - segment.startTime
        let progress = max(0, min(elapsed / transitionDuration, 1.0)) // Clamp between 0 and 1
        
        let baseOpacity = segment.actualOpacity
        
        // Fade
        if transition == .fade {
            return (basePosition, progress * baseOpacity)
        }
        
        // Edge-based slide-in transitions
        let offset: CGPoint = {
            switch transition {
            case .enterFromLeft: return CGPoint(x: 0, y: basePosition.y)
            case .enterFromRight: return CGPoint(x: videoSize.width, y: basePosition.y)
            case .enterFromTop: return CGPoint(x: basePosition.x, y: 0) // Flipped: top is 0
            case .enterFromBottom: return CGPoint(x: basePosition.x, y: videoSize.height) // Flipped: bottom is max
            case .enterFromTopLeft: return CGPoint(x: 0, y: 0)
            case .enterFromTopRight: return CGPoint(x: videoSize.width, y: 0)
            case .enterFromBottomLeft: return CGPoint(x: 0, y: videoSize.height)
            case .enterFromBottomRight: return CGPoint(x: videoSize.width, y: videoSize.height)
            default: return basePosition
            }
        }()
        
        let interpolatedX = offset.x + (basePosition.x - offset.x) * progress
        let interpolatedY = offset.y + (basePosition.y - offset.y) * progress
        
        return (CGPoint(x: interpolatedX, y: interpolatedY), baseOpacity)
    }
    
    func mixAudioSegments(audioSegments : [AudioSegment]) async -> URL? {
        let composition = AVMutableComposition()
//        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            completion(nil)
//            return
//        }
        
        var audioMixParams: [AVAudioMixInputParameters] = []
        
        for segment in audioSegments {
            let asset = AVURLAsset(url: segment.fileURL)
            guard let sourceTrack = try? await asset.loadTracks(withMediaType: .audio).first else { continue }
            
            let startTime = CMTime(seconds: segment.audioStartTime, preferredTimescale: 600)
            let duration = CMTime(seconds: segment.audioDuration, preferredTimescale: 600)
            let timelineStart = CMTime(seconds: segment.timeLineStartTime, preferredTimescale: 600)
            
            // ✅ Create a unique audio track for each segment
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            
            do {
                try audioTrack.insertTimeRange(
                    CMTimeRange(start: startTime, duration: duration),
                    of: sourceTrack,
                    at: timelineStart
                )
            } catch {
                print("❌ Failed to insert audio segment: \(error)")
                continue
            }
            
            let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
            
            // Fade in
            if segment.fadeInDuration > 0 {
                inputParams.setVolumeRamp(
                    fromStartVolume: 0.0,
                    toEndVolume: segment.actualVolume,
                    timeRange: CMTimeRange(
                        start: timelineStart,
                        duration: CMTime(seconds: segment.fadeInDuration, preferredTimescale: 600)
                    )
                )
            } else {
                inputParams.setVolume(segment.actualVolume, at: timelineStart)
            }
            
            // Fade out
            if segment.fadeOutDuration > 0 {
                let fadeOutStart = timelineStart + CMTime(seconds: segment.timeLineDuration - segment.fadeOutDuration, preferredTimescale: 600)
                inputParams.setVolumeRamp(
                    fromStartVolume: segment.actualVolume,
                    toEndVolume: 0.0,
                    timeRange: CMTimeRange(
                        start: fadeOutStart,
                        duration: CMTime(seconds: segment.fadeOutDuration, preferredTimescale: 600)
                    )
                )
            }
            
            audioMixParams.append(inputParams)
        }

        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioMixParams
        
        // Export
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

//    func combineVideoWithAudio(videoURL: URL, audioURL: URL, outputURL: URL, completion: @escaping (URL?) -> Void) async {
//        let mixComposition = AVMutableComposition()
//        
//        let videoAsset = AVURLAsset(url: videoURL)
//        let audioAsset = AVURLAsset(url: audioURL)
//        
//        guard let videoTrack = try? await videoAsset.loadTracks(withMediaType: .video).first,
//              let audioTrack = try? await audioAsset.loadTracks(withMediaType: .audio).first else {
//            completion(nil)
//            return
//        }
//        
//        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//        
//        try? await compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.load(.duration)),
//                                                    of: videoTrack,
//                                                    at: .zero)
//        
//        try? await compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: audioAsset.load(.duration)),
//                                                    of: audioTrack,
//                                                    at: .zero)
//        
//        // Export final video
//        try? FileManager.default.removeItem(at: outputURL)
//        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
//        exportSession?.outputURL = outputURL
//        exportSession?.outputFileType = .mp4
//        exportSession?.exportAsynchronously {
//            DispatchQueue.main.async {
//                completion(exportSession?.status == .completed ? outputURL : nil)
//            }
//        }
//    }

}

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
