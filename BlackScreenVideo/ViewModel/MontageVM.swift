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
    @Published var textSegmentSelectedID : UUID? = nil
    @Published var audioSegmentSelectedID : UUID? = nil
    @Published var shouldResetScroll: Bool = false

    @Published var currentTime: TimeInterval = 0
    @Published var rawTimeScale: CGFloat = PropertiesConstants.DefaultScaleTime
    @Published private(set) var timeScale: CGFloat = 1.0
    private var cancellables = Set<AnyCancellable>()

    @Published var tapX: CGFloat? = 0
    @Published var scrollOffset: CGFloat = 0
    
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
    let timeLineTimeOffset: TimeInterval = 20
    var maxDuration: TimeInterval {
        let textMax = textTracks[0].map { $0.startTime + $0.duration }.max() ?? 0
        let audioMax = audioSegments.map { $0.timeLineStartTime + $0.timeLineDuration }.max() ?? 0
        return max(textMax, audioMax)
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

    @Published var isPreviewPlaying: Bool = false
    var activeTexts: [TextSegment] {
        let activeTexts = self.textTracks
            .flatMap { $0 } // flatten all tracks into one array
            .filter { $0.startTime <= self.currentTime && self.currentTime <= $0.endTime }
        
        return activeTexts
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
        
        startDisplayLink()
        
        // Play audio segments that should start at or after currentTime
        startAudioPlaybackFromCurrentTime()
    }
    func startAudioPlaybackFromCurrentTime() {
        stopAllAudio() // Clean up previous players
        
        for segment in audioSegments {
            
//            let seekTime = max(0, relativeTime + segment.audioStartTime)
            
            let player = AVPlayer(url: segment.fileURL)
//            let time = CMTime(seconds: seekTime, preferredTimescale: 600)
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

    func pausePreviewPlayback() {
        isPreviewPlaying = false
        displayLink?.invalidate()
        displayLink = nil
        playbackStartDate = nil
        stopAllAudio()
    }
    func stopAllAudio() {
        playingAudioPlayers.forEach { $0.player.pause() }
        playingAudioPlayers.removeAll()
    }
    
    func stopAndResetPreviewPlayback() {
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
    
    
    func addAudioSegment(song : LocalSong){
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
                audioDuration: segment.audioDuration,
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
                audioDuration: segment.audioDuration,
                audioStartTime: segment.audioStartTime + timeIntoSegment,
                timeLineStartTime: time,
                timeLineDuration: segment.timeLineDuration - timeIntoSegment,
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
        }

    }
    
    //MARK: - UnDo / ReDo System functions
    
    
    var undoStackIsEmpty: Bool { undoStack.isEmpty }
    var redoStackIsEmpty: Bool { redoStack.isEmpty }
    private var undoStack: [(textTracks: [[TextSegment]], audioSegments: [AudioSegment])] = []
    private var redoStack: [(textTracks: [[TextSegment]], audioSegments: [AudioSegment])] = []
    private let maxHistory = 5
    
    func applyChangeWithRecordOldState(_ action : () -> Void) {
        // Save current state before the change
        recordStateForUndo()
        
        action()
    }
    func recordStateForUndo() {
        print("un do record , AudioSegment count : \(audioSegments.count) , TextSegment count : \(textTracks.count)")
        undoStack.append((textTracks: textTracks, audioSegments: audioSegments))
        if undoStack.count > maxHistory {
            undoStack.removeFirst()
        }
        redoStack.removeAll() // once we make a change, redo history is invalid
    }
    
    func undo() {
        guard let lastState = undoStack.popLast() else { return }
        redoStack.append((textTracks: textTracks, audioSegments: audioSegments))
        print("redoStack count : \(redoStack.count)")
        if redoStack.count > maxHistory {
            redoStack.removeFirst()
        }
        textTracks = lastState.textTracks
        print("last state textTracks count : \(textTracks)")
        audioSegments = lastState.audioSegments
        print("undo did made , AudioSegment count : \(audioSegments.count) , TextSegment count : \(textTracks.compactMap(\.count).reduce(0, +))")

    }
    
    func redo() {
        guard let nextState = redoStack.popLast() else { return }
        undoStack.append((textTracks: textTracks, audioSegments: audioSegments))
        if undoStack.count > maxHistory {
            undoStack.removeFirst()
        }
        textTracks = nextState.textTracks
        audioSegments = nextState.audioSegments
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
        
        isExportingVideo = true
        if let videoSize = self.videoSize , let previewSize = self.previewSize{
            exportManager = VideoExportManager(videoSize: videoSize.size,previewSize: previewSize)
            Task{
                exportManager!.exportVideo(textSegments: self.textTracks, audioSegments: self.audioSegments,duration: Double(maxDuration)) { progress in
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


                
            }

        }
        
    }
    
    func cancelVideoExporting(){
        exportManager?.exportingTask?.cancel()
        exportManager?.videoWriter?.cancelWriting()
        
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


