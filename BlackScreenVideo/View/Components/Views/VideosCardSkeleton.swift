//
//  VideosCardSkeleton.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 28/07/2025.
//


import SwiftUI

struct VideosCardSkeleton: View {
    @Environment(\.layoutDirection) var layoutDirection

    var isGrid: Bool = false
    var isForHome: Bool = false
    var isDoubleTitle: Bool = false
    var body: some View {
        VStack {
            // Title and Button
            if !isForHome {
                HStack {
                    skeletonItem
                        .frame(width: 120, height: 28)
                    
                    Spacer()
                    
                    if isDoubleTitle {
                        SkeletonView(RoundedRectangle(cornerRadius: 16))
                            .frame(width: 52, height: 38)
                    }
                    
                }
            }
            
            
            if isGrid {
                VStack{
                    ScrollView(.vertical) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 140)), count: 2), spacing: 10) {
                            ForEach(0..<4, id: \.self) { _ in
                                skeletonVideoItem
                                
                            }
                        }
                    }
                }
                .environment(\.layoutDirection,  LanguageSetting.shared.isRightToLeft ? .rightToLeft : .leftToRight)
                
            } else {
                HStack{
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                skeletonVideoItem
                                
                            }
                        }
                        
                    }
                    .scrollIndicators(.hidden)
                }
                .environment(\.layoutDirection,  LanguageSetting.shared.isRightToLeft ? .rightToLeft : .leftToRight)
            }
        }
        .padding(.top,0)
        
    }
    
    private var skeletonItem: some View {
        SkeletonView(.rect)
    }
    private var skeletonVideoItem: some View {
        VStack(alignment:.leading,spacing: 15){
            
            SkeletonView(RoundedRectangle(cornerRadius: 16))
                .frame(width: 140,height: 168)
            
            
            VStack(alignment:.leading,spacing:5){
                skeletonItem
                    .frame(width: 98,height: 15)
                
                HStack{
                    skeletonItem
                        .frame(width: 20,height: 10)
                    
                    skeletonItem
                        .frame(width: 40,height: 10)
                }
            }
            
            
        }
    }
    
}
struct SkeletonView<S : Shape>: View {
    var shape : S
    var color : Color
    init( _ shape: S, _ color: Color = Color.skeleton) {
        self.shape = shape
        self.color = color
    }
    @State private var isAnimating : Bool = false
    var body: some View {
        shape
            .fill(color)
            .overlay {
                GeometryReader { proxy in
                    let size = proxy.size
                    let skeletonWidth = size.width / 2
                    let blurRadius : CGFloat = max(skeletonWidth / 2 , 30)
                    let blurDiameter = blurRadius * 2
                    let minX = -(skeletonWidth + blurDiameter)
                    let maxX = size.width + skeletonWidth + blurDiameter
                    Rectangle()
                        .fill(.white)
                        .frame(width: skeletonWidth, height: size.height * 2)
                        .frame(height: size.height)
                        .blur(radius: blurRadius)
                        .rotationEffect(.init(degrees: rotation))
                        .blendMode(.softLight)
                    
                        .offset(x : isAnimating ? maxX : minX)
                    
                }
            }
            .clipShape(shape)
            .compositingGroup()
            .onAppear{
                guard !isAnimating else { return}
                withAnimation(animation){
                    self.isAnimating = true
                }
            }
            .onDisappear{
                isAnimating = false
            }
            .transaction{
                if $0.animation != animation {
                    $0.animation = .none
                }
            }
    }
    var rotation : Double {
        return 30
    }
    
    var animation : Animation {
        .easeInOut(duration: 1.5).repeatForever(autoreverses: false)
    }
    
}

#Preview(body: {
    VideosCardSkeleton(isGrid: false,isForHome: true,isDoubleTitle: true)
})
