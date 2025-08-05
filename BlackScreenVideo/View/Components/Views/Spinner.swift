//
//  Spinner.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 25/12/2024.
//

import SwiftUI
struct Spinner: View {
    @State private var rotationAngle = 0.0
    private let ringSize: CGFloat = 25

    var colors: [Color] = [Color.gray, Color.gray.opacity(0.3)]

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray.opacity(0))
            .ignoresSafeArea()
            .frame(width: 60,height: 60)
            .overlay {
                ZStack {
                    
                    ZStack {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: colors),
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                
                            )
                            .frame(width: ringSize, height: ringSize)
                        
                        
                        
                    }
                    .rotationEffect(.degrees(rotationAngle))
                    
                    .onAppear {
                        withAnimation(.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)) {
                                rotationAngle = 360.0
                            }
                    }
                    .onDisappear{
                        rotationAngle = 0.0
                    }
                }
            }
        

    }
}

#Preview {
    Spinner()
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
    
}
