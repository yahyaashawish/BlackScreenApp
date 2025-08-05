//
//  TimelineView 2.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 24/07/2025.
//

import SwiftUI
struct TimelineView: View {
    @ObservedObject var viewModel: MontageVM
    
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var visibleWidth: CGFloat = UIScreen.main.bounds.width
    var body: some View {
        let step = Int(viewModel.timeScale.rounded())
        let lastSecond = (Int(ceil(Double(viewModel.totalSeconds) / Double(step))) * step) + Int(viewModel.timeLineTimeOffset)
        
        //        let contentWidth = CGFloat(lastSecond) * viewModel.pixelsPerSecond
        GeometryReader { outerGeo in
            
            ZStack(alignment: .topLeading) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        // Track scroll offset using nested GeometryReader
                        HStack(spacing:0){
                            Color.clear
                                .frame(width: 1, height: 1)
                                .id("start")
                            VStack(alignment: .leading, spacing: 0) {
                                // Time ruler
                                HStack(spacing: 0) {
                                    
                                    ForEach(0...lastSecond, id: \.self) { second in
                                        if second % step == 0 {
                                            HStack(spacing: 0) {
                                                Spacer()
                                                Text(String(format: "%02d:%02d", second / 60, second % 60))
                                                    .font(.medium9)
                                                    .foregroundStyle(Color("9191A8"))
                                                    .id("cursor-\(second)")
                                                Spacer()

                                                    
                                                Rectangle()
                                                    .fill(Color("27272F"))
                                                    .frame(width: 1, height: 4)
                                                    
                                            }
                                            .frame(width: viewModel.pixelsPerSecond) // keep fixed spacing
                                        }
                                    }
                                }
                                .background(
                                    GeometryReader { reader in
                                        Color.clear.onAppear {
                                            visibleWidth = reader.size.width
                                            scrollViewProxy = proxy
                                        }
                                    }
                                )
                                .padding(.bottom,10)
                                .onChange(of: viewModel.currentTime) { _,_ in
                                    let margin: CGFloat = 40
                                    let actualXInTimeline = (viewModel.currentTime * viewModel.pixelsPerSecond) / viewModel.timeScale
                                    let tapX = actualXInTimeline - viewModel.scrollOffset
                                    let leftEdge: CGFloat = margin
                                    let rightEdge: CGFloat = 250
                                    if tapX < leftEdge || tapX > rightEdge {
                                        // It's outside the visible range, scroll
                                            viewModel.scrollToCurrentTime(proxy: proxy)
                                        
                                    }
                                }
                                // Text and audio tracks
                                TextTrackView(viewModel: viewModel)
                                    .padding(.bottom,10)
                                AudioTrackView(viewModel: viewModel)
                            }

                        }
                        .background(
                            GeometryReader { innerGeo in
                                Color.clear
                                    .onAppear {
                                        // Initial offset
                                        
                                        viewModel.scrollOffset = innerGeo.frame(in: .global).minX - outerGeo.frame(in: .global).minX
                                    }
                                    .onChange(of: innerGeo.frame(in: .global).minX) { oldValue ,newValue in
                                        
                                        // Track horizontal scroll
                                        viewModel.scrollOffset = outerGeo.frame(in: .global).minX - newValue
                                        
                                        let actualXInTimeline = (viewModel.currentTime * viewModel.pixelsPerSecond) / viewModel.timeScale
                                        let tappedX = actualXInTimeline - viewModel.scrollOffset
                                        if tappedX >= 0 {
                                            viewModel.tapX = tappedX
                                        }else{
                                            viewModel.tapX = nil
                                        }
                                    }
                            }
                            
                            
                        )
                        .background(
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(coordinateSpace: .named("timelineScroll")) { location in
                                    guard !viewModel.isPreviewPlaying else {return}
                                    let tappedX = location.x
                                    let actualXInTimeline = viewModel.scrollOffset + tappedX
                                    let selectedTime = max(0, actualXInTimeline / viewModel.pixelsPerSecond)
                                    viewModel.currentTime = selectedTime*viewModel.timeScale
                                    viewModel.tapX = tappedX
                                    
                                }
                        )
                    }
                    .coordinateSpace(name: "timelineScroll")
                    .onChange(of: viewModel.shouldResetScroll) { old ,shouldReset in
                        if shouldReset {
                            proxy.scrollTo("start", anchor: .leading)
                            viewModel.shouldResetScroll = false
                        }
                    }
                    .onChange(of: viewModel.timeScale) { _,_ in
                        viewModel.scrollToCurrentTime(proxy: proxy)
                    }
                    
                }
                
                // Cursor
                if let tapX = viewModel.tapX {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .frame(width: 2,height: 180)
                        .offset(x: tapX)
                }

            }
            .onChange(of: viewModel.currentTime) { oldTime ,newTime in
                let actualXInTimeline = newTime / viewModel.timeScale * viewModel.pixelsPerSecond
                let tappedX = actualXInTimeline - viewModel.scrollOffset
                
                // Only update if it's within visible range
                if tappedX >= 0 {
                    viewModel.tapX = tappedX
                } else {
                    viewModel.tapX = nil
                }
            }
        }
    }
}
