//
//  CircleProgressBarWithCancelButton.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 19/02/2025.
//


import SwiftUI

struct CircleProgressBarWithCancelButton: View {
    @Binding var progress: Double? // Progress value (0.0 to 1.0)
    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        ZStack {
            // Outer Circle (Background)
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.3)
                .foregroundColor(.gray)

            // Outer Circle (Progress)
            Circle()
                .trim(from: 0.0, to: CGFloat(progress ?? 0.0))
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundColor(.white)
                .rotationEffect(Angle(degrees: layoutDirection == .rightToLeft ? 90 : -90)) // Start from the top

                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.white)

                    
            
        }
        .frame(width: 24, height: 24) // Adjust size as needed
    }
}

#Preview {
    CircleProgressBarWithCancelButton(progress: .constant(0.2))
}
