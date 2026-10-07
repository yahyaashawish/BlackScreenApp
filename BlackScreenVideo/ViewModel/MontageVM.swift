//
//  MontageVM.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 14/05/2025.
//



import SwiftUI
import AVFoundation
import CoreImage
import Combine

class MontageVM: ObservableObject {
    @Published var videoSize : VideoSize?
    @Published var previewSize : CGSize? = nil
    @Published var textTracks: [[TextSegment]] = [[]]
    @Published var audioSegments: [AudioSegment] = []
    @Published var videoTrack: [VideoSegment] = []
    @Published var textSegmentSelectedID : UUID? = nil
    @Published var audioSegmentSelectedID : UUID? = nil
    @Published var videoSegmentSelectedID : UUID? = nil
    @Published var shouldResetScroll: Bool = false
    var canExportVideo: Bool { (textTracks.flatMap({ $0 } ).isEmpty && audioSegments.isEmpty && videoTrack.isEmpty )}

    @Published var currentTime: TimeInterval = 0
    @Published var rawTimeScale: CGFloat = PropertiesConstants.DefaultScaleTime
    @Published private(set) var timeScale: CGFloat = 1.0
    private var cancellables = Set<AnyCancellable>()

    @Published var tapX: CGFloat? = 0
    @Published var scrollOffset: CGFloat = 0
    
    init(initialSong: LocalSong?, videoSize: VideoSize){
        if let initialSong {
            self.addAudioSegment(song: initialSong)
        }
        self.videoSize = videoSize
        $rawTimeScale
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.timeScale = value
            }
            .store(in: &cancellables)
    }
    init(){
        
        
        $rawTimeScale
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.timeScale = value
            }
            .store(in: &cancellables)
    }
    let pixelsPerSecond: CGFloat = 65
    let timeLineTimeOffset: TimeInterval = 40
    var maxDuration: TimeInterval {
        let textMax = textTracks[0].map { $0.startTime + $0.duration }.max() ?? 0
        let audioMax = audioSegments.map { $0.timeLineStartTime + $0.timeLineDuration }.max() ?? 0
        let videoMax = videoTrack.map { $0.timeLineStartTime + $0.timeLineDuration }.max() ?? 0
        
        return max(textMax, audioMax,videoMax)
    }
    
    var textSegmentsDuration: TimeInterval {
        let textMax = textTracks[0].map { $0.startTime + $0.duration }.max() ?? 0
        return textMax
    }

    var totalSeconds: Int {
        Int(ceil(maxDuration))
    }

    
    func clearSegmentsSelection() {
        textSegmentSelectedID = nil
        audioSegmentSelectedID = nil
        videoSegmentSelectedID = nil

    }
    func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let anchor = UnitPoint.center // or .leading for left alignment
        proxy.scrollTo("cursor-\(Int(currentTime))", anchor: anchor)
    }
    func autoScrollTimelineIfNeeded(proxy: ScrollViewProxy, visibleWidth: CGFloat) {
        let cursorX = currentTime * pixelsPerSecond / timeScale
        
        // If cursor is near edge or out of screen, scroll to it
        let buffer: CGFloat = 100
        if cursorX < scrollOffset + buffer || cursorX > scrollOffset + visibleWidth - buffer {
            DispatchQueue.main.async {
                proxy.scrollTo("cursor-\(Int(cursorX))", anchor: .center)
                self.scrollOffset = max(0, cursorX - visibleWidth / 2)
            }
        }
    }
    //MARK: - Video Preview Section
    struct AudioSegmentPlayer {
        let id : UUID
        let player: AVPlayer
        let audioSegment: AudioSegment
        var isFadingOut : Bool = false
    }

    
    
    @Published var previewVideoPlayer: AVQueuePlayer = AVQueuePlayer()
    var currentSegmentVideoPlayerID: UUID? = nil
    @Published var isPreviewPlaying: Bool = false
    let videoPreviewManager = VideoPreviewManager()
    func handleCurrentVideoSegmentPlayer(currentTime: TimeInterval) {
        guard let activeSegment = videoTrack.first(where: {
            $0.timeLineStartTime <= currentTime &&
            currentTime < $0.timeLineEndTime
        }) else {
            if currentSegmentVideoPlayerID != nil {
                pauseVideoPlayback()
                currentSegmentVideoPlayerID = nil
            }
            return
        }
        
        // If we switched to a new video segment
        if activeSegment.id != currentSegmentVideoPlayerID {
            
            pauseVideoPlayback()
            previewVideoPlayer.removeAllItems()
            
            // Build repeated items
          
            
            // MARK: --- SMART SEEK LOGIC ---
            let relativeTime = currentTime - activeSegment.timeLineStartTime
            let videoDuration = activeSegment.videoOriginalDuration
            
            // Which repetition index we're inside
            let itemIndex = Int(relativeTime / videoDuration)
            
            // Position inside that repetition
            let offsetTime = relativeTime.truncatingRemainder(dividingBy: videoDuration)
            
            // Move forward in the queue to the correct item
            previewVideoPlayer.pause()
            
            previewVideoPlayer.removeAllItems()
            let items = videoPreviewManager.buildActualSegmentPlayerItems(segment: activeSegment)
            for item in items { previewVideoPlayer.insert(item, after: nil) }
            
            for _ in 0..<itemIndex {
                previewVideoPlayer.advanceToNextItem()
            }
            
            let seekTime = CMTime(seconds: offsetTime + activeSegment.videoStartTime, preferredTimescale: 600)
            previewVideoPlayer.seek(to: seekTime)
            previewVideoPlayer.volume = activeSegment.actualVolume

            previewVideoPlayer.play()
            currentSegmentVideoPlayerID = activeSegment.id
        }
        
        
    }

    var activeTexts: [TextSegment] {
        let activeTexts = self.textTracks
            .flatMap { $0 } // flatten all tracks into one array
            .filter { $0.startTime <= self.currentTime && self.currentTime <= $0.endTime }
        
        return activeTexts
    }
    
    var activeVideoSegment : VideoSegment? {
        let segment = self.videoTrack.first(where: {$0.timeLineStartTime <= self.currentTime && self.currentTime <= $0.timeLineEndTime})
        return segment
    }
    @Published var currentTimeVideoImage : UIImage? = nil

    func getCurrentFrameForSegment(
        maximumSize: CGSize? = nil
    ) {
        if let segment = self.activeVideoSegment {
            guard currentTime >= segment.timeLineStartTime,
                  currentTime <= segment.timeLineEndTime else {
                currentTimeVideoImage = nil
                return
            }
            
            // 2. Convert TL time → segment-relative time
            let segmentRelativeTime = currentTime - segment.timeLineStartTime
            
            // 3. Compute actual video time with looping
            let original = segment.videoOriginalDuration
            var videoTime = (segment.videoStartTime + segmentRelativeTime)
                .truncatingRemainder(dividingBy: original)
            
            if videoTime < 0 { videoTime += original }  // safety
            
            // 4. Now extract the actual frame
            let asset = AVURLAsset(url: segment.fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            
            generator.appliesPreferredTrackTransform = true
            
            if let maxSize = maximumSize {
                generator.maximumSize = maxSize
            }
            
            let cmTime = CMTime(seconds: videoTime, preferredTimescale: 600)
            
                generator.generateCGImageAsynchronously(for: cmTime) { cgImage, time, error in
                    if let cgImage = cgImage {
                        DispatchQueue.main.async{
                            self.currentTimeVideoImage =  UIImage(cgImage: cgImage)
                        }
                    }else{
                        DispatchQueue.main.async{
                            self.currentTimeVideoImage = nil
                        }
                    }

                }
            
        }else{
            currentTimeVideoImage = nil
        }
        // 1. Ensure currentTime is inside this segment
        
    }

    var playingAudioPlayers: [AudioSegmentPlayer] = []
    var currentAudioPlayerID: UUID? = nil
    private var displayLink: CADisplayLink?
    private var playbackStartTime: TimeInterval = 0
    private var playbackStartDate: Date?
    
    
    

    func startPreviewPlayback() {
        guard !isPreviewPlaying else { return }
        

        isPreviewPlaying = true
        clearSegmentsSelection()
        playbackStartTime = currentTime == 0 ? -0.5 : currentTime
        playbackStartDate = Date()
        startAudioPlaybackFromCurrentTime()
        startDisplayLink()
        
    }
    func startAudioPlaybackFromCurrentTime() {
        stopAllAudio() // Clean up previous players
        
        for segment in audioSegments {
            
            
            let player = AVPlayer(url: segment.fileURL)
            player.volume = segment.actualVolume
            let audioSegmentPlayer = AudioSegmentPlayer(id: UUID(),player: player,audioSegment: segment)
            playingAudioPlayers.append(audioSegmentPlayer)
            
            
        }
    }
    private func startDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePlaybackTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updatePlaybackTime() {
        guard let startDate = playbackStartDate else { return }
        currentTime = playbackStartTime + Date().timeIntervalSince(startDate)
        if self.currentTime >= self.maxDuration {
            self.pausePreviewPlayback()
        }
        handleCurrentVideoSegmentPlayer(currentTime: currentTime)
        if let active = playingAudioPlayers.first(where: {
            $0.audioSegment.timeLineStartTime <= currentTime && currentTime < $0.audioSegment.timeLineEndTime
        }) {
            if currentAudioPlayerID != active.id {
                // New segment started, stop previous one if any
                if let previous = playingAudioPlayers.first(where: { $0.id == currentAudioPlayerID }) {
                    previous.player.pause()
                }
               
                // Start the new segment
                currentAudioPlayerID = active.id
                let seekTime = currentTime - active.audioSegment.timeLineStartTime + active.audioSegment.audioStartTime
                // fade in check time
                let fadeInStart = active.audioSegment.audioStartTime
                let fadeInEnd = fadeInStart + active.audioSegment.fadeInDuration
                let isInFadeInPhase = seekTime >= fadeInStart && seekTime < fadeInEnd
                
                
                // apply fade in current volume
                if isInFadeInPhase {
                    let progress = (seekTime - fadeInStart) / active.audioSegment.fadeInDuration
                    let initialVolume = Float(progress) * active.audioSegment.actualVolume
                    active.player.volume = initialVolume
                } else {
                    active.player.volume = active.audioSegment.actualVolume
                }
                
               
                
                active.player.seek(to: CMTime(seconds: seekTime, preferredTimescale: 600)) { _ in
                    active.player.play()
                    if isInFadeInPhase {
                        let remainingFadeDuration = fadeInEnd - seekTime
                        let currentVolume = active.player.volume
                        
                        self.applyFade(
                            to: active.player,
                            fromVolume: currentVolume,
                            toVolume: active.audioSegment.actualVolume,
                            duration: remainingFadeDuration,
                            fadeIn: true
                        )
                    }
                }
            }else{
                // fade out check time
                let fadeOutStart = active.audioSegment.timeLineEndTime - active.audioSegment.fadeOutDuration
                let fadeOutEnd = active.audioSegment.timeLineEndTime
                let isInFadeOutPhase = currentTime >= fadeOutStart && currentTime < fadeOutEnd
                // apply fade out current volume
                if isInFadeOutPhase && !active.isFadingOut{
                    if let activeAudioIndex = playingAudioPlayers.firstIndex(where: { $0.id == active.id }){
                        playingAudioPlayers[activeAudioIndex].isFadingOut = true
                    }

                    let progress = (fadeOutEnd - currentTime) / active.audioSegment.fadeOutDuration
                    let currentVolume = Float(progress) * active.audioSegment.actualVolume
                    active.player.volume = currentVolume
                    
                    let remainingDuration = fadeOutEnd - currentTime
                    
                    self.applyFade(
                        to: active.player,
                        fromVolume: currentVolume,
                        toVolume: 0,
                        duration: remainingDuration,
                        fadeIn: false
                    )
                }
            }
            // else: already playing, nothing to do
        } else {
            // No matching segment now, pause any active one
            if let previous = playingAudioPlayers.first(where: { $0.id == currentAudioPlayerID }) {
                previous.player.pause()
                previous.player.volume = previous.audioSegment.actualVolume
                if let prevAudioIndex = playingAudioPlayers.firstIndex(where: { $0.id == previous.id }){
                    playingAudioPlayers[prevAudioIndex].isFadingOut = false
                }
            }
            currentAudioPlayerID = nil
        }
            
           
        

    }
    var volumeTimer: Timer?

    func applyFade(to player: AVPlayer,
                   fromVolume: Float,
                   toVolume: Float,
                   duration: TimeInterval,
                   fadeIn: Bool) {
        
        volumeTimer?.invalidate()
        
        let steps = 20
        let interval = duration / Double(steps)
        var currentStep = 0
        
        let delta = (toVolume - fromVolume) / Float(steps)
        
        volumeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            player.volume = fromVolume + Float(currentStep) * delta
            currentStep += 1
            if currentStep >= steps {
                player.volume = toVolume
                timer.invalidate()
                self?.volumeTimer = nil
            }
        }
    }
    func pauseVideoPlayback(){
        previewVideoPlayer.pause()
        previewVideoPlayer.removeAllItems()
        currentSegmentVideoPlayerID = nil
        print("video playback paused")
    }
    func pausePreviewPlayback() {
        if isPreviewPlaying {
            pauseVideoPlayback()
            stopAllAudio()
            isPreviewPlaying = false
            displayLink?.invalidate()
            displayLink = nil
            playbackStartDate = nil
        }
        
    }
    func stopAllAudio() {
        playingAudioPlayers.forEach { $0.player.pause() }
        playingAudioPlayers.removeAll()
    }
    
    func stopAndResetPreviewPlayback() {
        pauseVideoPlayback()
        pausePreviewPlayback()
        currentTime = 0
        shouldResetScroll = true
    }
    
    
    //MARK: - Audio Segments Functions
    
    func updateTime(fromScroll offset: CGFloat) {
        let time = max(0, offset / pixelsPerSecond)
        currentTime = time
        scrollOffset = offset
    }
    
    
    func addAudioSegment(song : LocalSong?){
        if let song = song {
            let lastEndTime = audioSegments
                .map { $0.timeLineStartTime + $0.timeLineDuration }
                .max() ?? 0
            
            let newSegment = AudioSegment(
                name: song.name,
                fileURL: song.url,
                audioOriginalDuration: TimeInterval(song.duration),
                timeLineStartTime: lastEndTime == 0 ? 0 : lastEndTime + 1,
                timeLineDuration: TimeInterval(song.duration),
                fadeInDuration: 0,
                fadeOutDuration: 0
            )
            
            if audioSegments.isEmpty{
                audioSegments.append(newSegment)
                
            }else{
                applyChangeWithRecordOldState {
                    audioSegments.append(newSegment)
                }
            }
        }
        
        
    }
    
    func deleteSelectedAudioSegment( segmentIndex : Int){
        applyChangeWithRecordOldState {
            self.audioSegments.remove(at: segmentIndex)
            self.audioSegmentSelectedID = nil
        }
        
    }
    func selectAudioSegment(segment : AudioSegment){
        if !isPreviewPlaying{
            if audioSegmentSelectedID == segment.id{
                audioSegmentSelectedID = nil
                
                return
            }
            audioSegmentSelectedID = segment.id
            
            textSegmentSelectedID = nil
            videoSegmentSelectedID = nil

        }
    }
    
    func splitAudioSegment(at time: TimeInterval) {
        guard let index = audioSegments.firstIndex(where: { segment in
            time >= segment.timeLineStartTime && time <= segment.timeLineEndTime
        }) else {
            return
        }
        applyChangeWithRecordOldState {
            
            let segment = audioSegments[index]
            let timeIntoSegment = time - segment.timeLineStartTime
            
            // Skip if trying to split at segment start or end
            guard timeIntoSegment > 0, timeIntoSegment < segment.timeLineDuration else { return }
            
            // Remove the original segment
            audioSegments.remove(at: index)
            
            // Create the two split segments
            let firstAudio = AudioSegment(
                name: segment.name,
                fileURL: segment.fileURL,
                audioOriginalDuration: segment.audioOriginalDuration,
                audioDuration: timeIntoSegment,
                audioStartTime: segment.audioStartTime,
                timeLineStartTime: segment.timeLineStartTime,
                timeLineDuration: timeIntoSegment,
                fadeInDuration: segment.fadeInDuration,
                fadeOutDuration: segment.fadeOutDuration,
                amplitudes: segment.amplitudes
            )
            
            let secondAudio = AudioSegment(
                name: segment.name,
                fileURL: segment.fileURL,
                audioOriginalDuration: segment.audioOriginalDuration,
                audioDuration: segment.timeLineDuration - timeIntoSegment,
                audioStartTime: segment.audioStartTime + timeIntoSegment,
                timeLineStartTime: time,
                timeLineDuration: segment.timeLineDuration - timeIntoSegment ,
                fadeInDuration: segment.fadeInDuration,
                fadeOutDuration: segment.fadeOutDuration,
                amplitudes: segment.amplitudes
            )
            
            
            // Insert the new segments back in the correct order
            audioSegments.insert(firstAudio, at: index)
            audioSegments.insert(secondAudio, at: index)
            
            
        }
    }
    
    func exchangeSelectedSegment(with song : LocalSong){
        if let segmentId = self.audioSegmentSelectedID {

            if let segmentIndex =  self.audioSegments.firstIndex(where: { $0.id == segmentId }) {

                let oldSegment = self.audioSegments[segmentIndex]
                let newSegment = AudioSegment(
                    name: song.name,
                    fileURL: song.url,
                    audioOriginalDuration: TimeInterval(song.duration),
                    timeLineStartTime: oldSegment.timeLineStartTime,
                    timeLineDuration: TimeInterval(song.duration),
                    fadeInDuration: 0,
                    fadeOutDuration: 0
                )
                var newSegmentsArray : [AudioSegment] = [newSegment]
                applyChangeWithRecordOldState {
                    for seg in audioSegments {
                        guard seg.id != oldSegment.id else {
                            continue
                        }
                        if seg.timeLineStartTime >= oldSegment.timeLineEndTime {
                            var updatedSegment = seg
                            updatedSegment.timeLineStartTime = newSegment.timeLineEndTime + (seg.timeLineStartTime - oldSegment.timeLineEndTime)
                            newSegmentsArray.append(updatedSegment)
                        }else{
                            newSegmentsArray.append(seg)
                        }
                        
                        
                    }
                    self.audioSegments = newSegmentsArray
                }
            }
        }
    }

    //MARK: - Video Segments Functions
    
    
    func addVideoSegment(video : LocalVideo){
        let lastEndTime = videoTrack
            .map { $0.timeLineStartTime + $0.timeLineDuration }
            .max() ?? 0
        
             
                 if let duration = video.duration{
                    let newSegment = VideoSegment(
                        name: video.name,
                        fileURL: video.video_url,
                        thumbnail: nil,
                        videoOriginalDuration: duration,
                        timeLineStartTime: lastEndTime == 0 ? 0 : lastEndTime + 1,
                        timeLineDuration: duration
                    )
                     self.applyChangeWithRecordOldState {
                         self.videoTrack.append(newSegment)
                     }
                     
                     Task {
                        video.getVideoThumb { thumb in
                            if let thumb = thumb{
                                let videoIndex = self.videoTrack.firstIndex { video in
                                    video.id == newSegment.id
                                }
                                                            
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    if let videoIndex = videoIndex{
                                        self.videoTrack[videoIndex].thumbnail = thumb
                                    }
                                }
                            }
                         }
                     }
                    
                }
            
        

        
    }
    func selectVideoSegment(segment : VideoSegment){
        if !isPreviewPlaying{
            if videoSegmentSelectedID == segment.id{
                videoSegmentSelectedID = nil
                return
            }
            videoSegmentSelectedID = segment.id
            
            audioSegmentSelectedID = nil
            textSegmentSelectedID = nil
        }
        
    }
    
    func deleteSelectedVideoSegment( segmentIndex : Int){
        applyChangeWithRecordOldState {
            self.videoTrack.remove(at: segmentIndex)
            self.videoSegmentSelectedID = nil
        }
        
    }
    
    func splitVideoSegment(at time: TimeInterval) {
        guard let index = videoTrack.firstIndex(where: { segment in
            time >= segment.timeLineStartTime && time <= segment.timeLineEndTime
        }) else {
            return
        }
        applyChangeWithRecordOldState {
            
            let segment = videoTrack[index]
            let timeIntoSegment = time - segment.timeLineStartTime
            
            // Skip if trying to split at segment start or end
            guard timeIntoSegment > 0, timeIntoSegment < segment.timeLineDuration else { return }
            
            // Remove the original segment
            videoTrack.remove(at: index)
            
            // Create the two split segments
            
            let firstSegment = VideoSegment(
                name: segment.name,
                fileURL: segment.fileURL,
                thumbnail: segment.thumbnail,
                videoOriginalDuration: segment.videoOriginalDuration,
                videoStartTime: segment.videoStartTime,
                timeLineStartTime: segment.timeLineStartTime,
                timeLineDuration: timeIntoSegment
            )
            let secondSegment = VideoSegment(
                name: segment.name,
                fileURL: segment.fileURL,
                thumbnail: segment.thumbnail,
                videoOriginalDuration: segment.videoOriginalDuration,
                videoStartTime: segment.videoStartTime + timeIntoSegment,
                timeLineStartTime: time,
                timeLineDuration: segment.timeLineDuration - timeIntoSegment
            )
            
            
            
            // Insert the new segments back in the correct order
            videoTrack.insert(firstSegment, at: index)
            videoTrack.insert(secondSegment, at: index)
            print("new segments inserted \(firstSegment) and \(secondSegment)")

        }
    }
    
    func exchangeSelectedVideoSegment(with video : LocalVideo){
        if let segmentId = self.videoSegmentSelectedID {
            
            if let segmentIndex =  self.videoTrack.firstIndex(where: { $0.id == segmentId }) {
                
                let oldSegment = self.videoTrack[segmentIndex]

                if let duration = video.duration{
                    let newSegment = VideoSegment(
                        name: video.name,
                        fileURL: video.video_url,
                        thumbnail: nil,
                        videoOriginalDuration: duration,
                        timeLineStartTime: oldSegment.timeLineStartTime,
                        timeLineDuration: duration
                    )
                    
                    var newSegmentsArray : [VideoSegment] = [newSegment]
                    applyChangeWithRecordOldState {
                        for seg in videoTrack {
                            guard seg.id != oldSegment.id else {
                                continue
                            }
                            if seg.timeLineStartTime >= oldSegment.timeLineEndTime {
                                var updatedSegment = seg
                                updatedSegment.timeLineStartTime = newSegment.timeLineEndTime + (seg.timeLineStartTime - oldSegment.timeLineEndTime)
                                newSegmentsArray.append(updatedSegment)
                            }else{
                                newSegmentsArray.append(seg)
                            }
                            
                            
                        }
                        self.videoTrack = newSegmentsArray
                        Task {
                            video.getVideoThumb { thumb in
                                if let thumb = thumb{
                                    let videoIndex = self.videoTrack.firstIndex { video in
                                        video.id == newSegment.id
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        if let videoIndex = videoIndex{
                                            self.videoTrack[videoIndex].thumbnail = thumb
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    //MARK: - Text Segments Functions
    
    var lastSegmentID: UUID? = nil
    func vacantTrackIndex(for start: TimeInterval,
                          end: TimeInterval,
                          ignoring segmentID: UUID? = nil) -> Int? {
        
        for (idx, row) in textTracks.enumerated() {
            let overlaps = row.contains {
                $0.id != segmentID &&
                !(end <= $0.startTime || start >= $0.endTime)
            }
            if !overlaps { return idx }
        }
        return nil
    }
    
    /// ensure requested track exists; create rows on-demand
    func ensureTrack(_ index: Int) {
        while textTracks.count <= index { textTracks.append([]) }
    }
    
    
    /// move a segment to a NEW track (creates it if needed)
    func move(_ segment: TextSegment, toTrack newIdx: Int) {
        // remove from old
        if let oldIdx = textTracks.firstIndex(where: { $0.contains(where: { $0.id == segment.id }) }),
           let pos = textTracks[oldIdx].firstIndex(where: { $0.id == segment.id }) {
            textTracks[oldIdx].remove(at: pos)
            if textTracks[oldIdx].isEmpty {
                textTracks.remove(at: oldIdx)
            }
        }
        // insert into new
        ensureTrack(newIdx)
        var updated = segment
        updated.trackIndex = newIdx
        textTracks[newIdx].append(updated)
        // keep row sorted
        textTracks[newIdx].sort { $0.startTime < $1.startTime }
    }
    func addTextSegment(with text: String) {
        
        if let previewSize = previewSize {
            let defaultDuration: TimeInterval = 10
            
//            let lastEndTime = textTracks[0].map { $0.startTime + $0.duration }.max() ?? 0
//            let startTime: TimeInterval = lastEndTime == 0 ? 0 : lastEndTime + 1
            let startTime: TimeInterval = currentTime
            let centerPosition: CGPoint = CGPoint(x: previewSize.width / 2, y: previewSize.height / 2)
            let newSegment = TextSegment(content: text, startTime: startTime , duration: defaultDuration,position: centerPosition)
            
            applyChangeWithRecordOldState {
                textTracks[0].append(newSegment)
                if let newTrack = vacantTrackIndex(for: startTime, end: newSegment.endTime,ignoring: newSegment.id) {
                    if newTrack != newSegment.trackIndex {
                        move(newSegment, toTrack: newTrack)
                    }
                } else {
                    move(newSegment, toTrack: textTracks.count) // New track
                }
                
                lastSegmentID = newSegment.id
            }

            
        }
        
    }
    func splitSelectedTextSegment() {
        if let selectedSegmentId = textSegmentSelectedID{
            if let trackIndex = textTracks.firstIndex(where: { $0.contains(where: { $0.id == selectedSegmentId }) }){
                
                if let segmentIndex = textTracks[trackIndex].firstIndex(where: { seg in
                    seg.id == selectedSegmentId
                }){
                    let time = currentTime
                   
                    
                    let segment = textTracks[trackIndex][segmentIndex]
                    
                    let timeIntoSegment = time - segment.startTime
                    
                    // Skip if trying to split at segment start or end
                    guard timeIntoSegment > 0, timeIntoSegment < segment.duration else { return }
                    applyChangeWithRecordOldState {

                    // Remove the original segment
                    textTracks[trackIndex].remove(at: segmentIndex)
                    
                    // Create the two split segments
                    let firstSegment = TextSegment(
                        content: segment.content,
                        startTime: segment.startTime,
                        duration: timeIntoSegment,
                        trackIndex: segment.trackIndex,
                        font: segment.font,
                        alignment: segment.alignment,
                        fontSize: segment.fontSize,
                        textColor: segment.textColor,
                        backgroundColor: segment.backgroundColor,
                        opacity: segment.opacity,
                        shadow: segment.shadow,
                        textWrapping: segment.textWrapping,
                        transitionType: segment.transitionType,
                        position: segment.position
                    
                    )
                    let secondSegment = TextSegment(
                        content: segment.content,
                        startTime: time,
                        duration: segment.duration - timeIntoSegment,
                        trackIndex: segment.trackIndex,
                        font: segment.font,
                        alignment: segment.alignment,
                        fontSize: segment.fontSize,
                        textColor: segment.textColor,
                        backgroundColor: segment.backgroundColor,
                        opacity: segment.opacity,
                        shadow: segment.shadow,
                        textWrapping: segment.textWrapping,
                        transitionType: segment.transitionType,
                        position: segment.position
                        
                    )
                                        
                    
                                      
                    // Insert the new segments back in the correct order
                        textTracks[trackIndex].insert(firstSegment, at: segmentIndex)
                        textTracks[trackIndex].insert(secondSegment, at: segmentIndex)
                        
                    }
                    
                }
            }
            
        }
        
    }
    
    func applyTransitionOnAllTextSegments(_ transition: TextTransitionType){
        applyChangeWithRecordOldState {
            
            for trackIndex in 0..<textTracks.count{
                for segmentIndex in 0..<textTracks[trackIndex].count{
                    textTracks[trackIndex][segmentIndex].transitionType = transition
                }
            }
        }
    }
    func applyBackgroundOnAllTextSegments(_ color: TextSegmentColor , _ type : SegmentColorType){
        applyChangeWithRecordOldState {
            
            for trackIndex in 0..<textTracks.count{
                for segmentIndex in 0..<textTracks[trackIndex].count{
                    switch type {
                    case .text:
                        textTracks[trackIndex][segmentIndex].textColor = color
                        
                    case .background:
                        textTracks[trackIndex][segmentIndex].backgroundColor = color
                    }
                }
            }
        }
    }
    
    func applyShadowOnAllTextSegments(_ shadow: TextSegmentShadow){
        applyChangeWithRecordOldState {
            
            for trackIndex in 0..<textTracks.count{
                for segmentIndex in 0..<textTracks[trackIndex].count{
                    textTracks[trackIndex][segmentIndex].shadow = shadow
                }
            }
        }
    }
    func applySurroundOnAllTextSegments(_ surround: TextSegmentWrapping){
        applyChangeWithRecordOldState {
            
            for trackIndex in 0..<textTracks.count{
                for segmentIndex in 0..<textTracks[trackIndex].count{
                    textTracks[trackIndex][segmentIndex].textWrapping = surround
                }
            }
        }
    }
    func applyFontOnAllTextSegments(_ font: LocalFont){
        applyChangeWithRecordOldState {
            
            for trackIndex in 0..<textTracks.count{
                for segmentIndex in 0..<textTracks[trackIndex].count{
                    textTracks[trackIndex][segmentIndex].font = font
                }
            }
        }
    }
    func updateTextSegmentPosition(id: UUID, to newPosition: CGPoint) {
        applyChangeWithRecordOldState {
            
            for (trackIndex, track) in textTracks.enumerated() {
                if let segmentIndex = track.firstIndex(where: { $0.id == id }) {
                    textTracks[trackIndex][segmentIndex].position = newPosition
                    return
                }
            }
        }
    }
    func deleteSelectedTextSegment( trackIndex : Int , segmentIndex : Int){
        applyChangeWithRecordOldState {
            self.textTracks[trackIndex].remove(at: segmentIndex)
            self.textSegmentSelectedID = nil
        }
        
    }

    
    func selectTextSegment(segment : TextSegment){
        if !isPreviewPlaying{
            if textSegmentSelectedID == segment.id{
                textSegmentSelectedID = nil
                return
            }
            textSegmentSelectedID = segment.id
            
            audioSegmentSelectedID = nil
            videoSegmentSelectedID = nil
        }

    }
    
    //MARK: - UnDo / ReDo System functions
    
    
    var undoStackIsEmpty: Bool { undoStack.isEmpty }
    var redoStackIsEmpty: Bool { redoStack.isEmpty }
    private var undoStack: [(textTracks: [[TextSegment]], audioSegments: [AudioSegment],videoTrack:[VideoSegment])] = []
    private var redoStack: [(textTracks: [[TextSegment]], audioSegments: [AudioSegment],videoTrack:[VideoSegment])] = []
    private let maxHistory = 5
    
    func applyChangeWithRecordOldState(_ action :  () -> Void) {
        // Save current state before the change
        recordStateForUndo()
        
        action()
    }
    func recordStateForUndo() {
        undoStack.append((textTracks: textTracks, audioSegments: audioSegments,videoTrack:videoTrack))
        if undoStack.count > maxHistory {
            undoStack.removeFirst()
        }
        redoStack.removeAll() // once we make a change, redo history is invalid
    }
    
    func undo() {
        guard let lastState = undoStack.popLast() else { return }
        redoStack.append((textTracks: textTracks, audioSegments: audioSegments,videoTrack:videoTrack))
        print("redoStack count : \(redoStack.count)")
        if redoStack.count > maxHistory {
            redoStack.removeFirst()
        }
        textTracks = lastState.textTracks
        print("last state textTracks count : \(textTracks)")
        audioSegments = lastState.audioSegments
        print("undo did made , AudioSegment count : \(audioSegments.count) , TextSegment count : \(textTracks.compactMap(\.count).reduce(0, +))")
        videoTrack = lastState.videoTrack
    }
    
    func redo() {
        guard let nextState = redoStack.popLast() else { return }
        undoStack.append((textTracks: textTracks, audioSegments: audioSegments,videoTrack:videoTrack))
        if undoStack.count > maxHistory {
            undoStack.removeFirst()
        }
        textTracks = nextState.textTracks
        audioSegments = nextState.audioSegments
        videoTrack = nextState.videoTrack

    }
    func resetUnDoHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    //MARK: - Export Video Section
    @Published var exportProgress: Double = 0
    @Published var isExportingVideo: Bool = false
    @Published var outputURL: URL? = nil
    @Published var outputThumbnail: UIImage? = nil
    var exportManager: VideoExportManager? = nil
    
    @MainActor
    func exportVideo() async{
        
        if let videoSize = self.videoSize , let previewSize = self.previewSize{
            isExportingVideo = true
            exportProgress = 0
            exportManager = VideoExportManager(videoSize: videoSize.size,previewSize: previewSize)
            Task{
                exportManager!.exportVideo(textSegments: self.textTracks, audioSegments: self.audioSegments, videoSegments: self.videoTrack,duration: Double(maxDuration)) { progress in
                    DispatchQueue.main.async {
                        self.exportProgress = progress
                    }
                } completion: { result in
                    switch result{
                    case .success(let url):
                        Task { @MainActor in
                            self.outputURL = url
                            self.outputThumbnail = await self.generateThumbnail()
                            self.isExportingVideo = false
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            self.savingVideoAlert = .videoExtractingError
                            self.presentAlert = true
                            self.isExportingVideo = false
                        }
                    }
                }
//                exportManager?.exportVideoSegments(segments: videoTrack, fullDuration: maxDuration, renderSize: videoSize.size) { progress in
//                    DispatchQueue.main.async {
//                                                self.exportProgress = progress
//                                            }
//                } completion: { outputURL in
//                    Task { @MainActor in
//                        if let url = outputURL {
//                            self.exportManager?.addTextOverlayToVideo(videoURL: url, textSegments: self.textTracks,renderSize: videoSize.size,previewSize : previewSize) { progress in
//                                DispatchQueue.main.async {
//                                    self.exportProgress = progress
//                                    
//                                }
//                            } completion: { textURL in
//                                DispatchQueue.main.async {
//                                    
//                                    self.outputURL = textURL
//                                    self.isExportingVideo = false
//                                }
//                            }
//                        }else{
//                            self.outputURL = nil
//                            self.presentAlert = true
//                            self.isExportingVideo = false
//                        }
//                    }
//                }


                
            }

        }
        
        
    }
    
    @MainActor
    func cancelVideoExporting(){
        print("cancelling video export")
        exportManager?.cancelExport()
    }
    
    //MARK: - Exported Video Functions
    let fileManager = VideoFileManager.shared
    let coreData = CoreDataHelper.shared
    let context = CoreDataHelper.shared.persistentContainer.viewContext
    @Published var savingVideoAlert : ExtractedVideoAlert = .none
    @Published var presentAlert: Bool = false
    
    func saveVideo(with title: String)  {
        presentAlert = false

        guard title.isEmpty == false else {
            savingVideoAlert = .videoTitleEmpty
            presentAlert = true
            return
        }
        if let videoURL = outputURL , let thumbImage = outputThumbnail{
            let id = UUID()
            let key = "\(title)-\(getFileNameDateString())"
            do {
                if let savedUrls = try fileManager.saveVideo(key: key, from: videoURL, thumb: thumbImage){
                    let newVideo = Video(context: context)
                    newVideo.id = id
                    newVideo.name = key
                    newVideo.title = title
                    newVideo.url = savedUrls.videoURL.absoluteString
                    newVideo.thumb_image_url = savedUrls.thumbURL.absoluteString
                    newVideo.created_at = Date()
                    coreData.saveContext()
                    savingVideoAlert = .videoSaved
                    presentAlert = true

                }
            } catch{
                savingVideoAlert = .videoSavingError
                presentAlert = true
            }
            
            
        }
    }
    func getFileNameDateString() -> String {
        let now = Date()
        let formatter = DateFormatter()
        
        // Set the desired format
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        
        return formatter.string(from: now)
    }

    
    func generateThumbnail(
        at time: CMTime = CMTime(seconds: 1, preferredTimescale: 60)
    ) async -> UIImage? {
        if let url = outputURL{
            
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true // Fix orientation
            
            return await withCheckedContinuation { continuation in
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, actualTime, result, error in
                    if let cgImage = cgImage {
                        continuation.resume(returning: UIImage(cgImage: cgImage))
                    } else {
                        print("❌ Failed to generate thumbnail: \(error?.localizedDescription ?? "unknown error")")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }else{
            return nil
        }
    }
}

