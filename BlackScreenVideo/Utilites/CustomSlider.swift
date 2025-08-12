//
//  CustomSlider.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 04/06/2025.
//

import SwiftUI
struct CustomSlider: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Binding var value: CGFloat
    var range: ClosedRange<CGFloat> = 1...20
    var thumbSize: CGFloat = 24
    var trackHeight: CGFloat = 4
    var fillColor: Color = Color("4A4AFF")
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clampedValue = min(max(value, range.lowerBound), range.upperBound)
            let percent = (clampedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            let xOffset =  percent * width

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: trackHeight)

                // Filled portion
                Capsule()
                    .fill(fillColor)
                    .frame(width: xOffset, height: trackHeight)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(radius: 1)
                    .offset(x: layoutDirection == .leftToRight ? xOffset - thumbSize / 2 : -(width - xOffset) + thumbSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newPercent = max(0, min(1, gesture.location.x / width))
                                value = range.lowerBound + newPercent * (range.upperBound - range.lowerBound)
                            }
                    )
            }
        }
        .frame(height: max(thumbSize, 44)) // Ensure enough height for touch
    }
}
