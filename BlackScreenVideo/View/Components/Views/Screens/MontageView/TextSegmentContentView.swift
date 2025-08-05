//
//  TextSegmentContentView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 24/06/2025.
//


import SwiftUI
struct TextSegmentContentView : View {
    @State private var size: CGSize = .zero
    @GestureState private var dragOffset = CGSize.zero

    let segment : TextSegment
    let previewSize: CGSize
    let isSelected : Bool
    let isPreviewPlaying : Bool
    let onMove: (CGPoint) -> Void

    var body: some View {
        ZStack(alignment:.topTrailing){
            
            if isPreviewPlaying {
                Text(segment.content)
                    .textSegmentStyle(segment: segment)
                    .position(
                        x: segment.position.x,
                        y: segment.position.y
                    )
                    

            }else{
             
                
                Text(segment.content)
                
                    .lineLimit(1)
                    .textSegmentStyle(segment: segment)
                    .overlay {
                        if isSelected {
                            Rectangle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(Color("01B5FF"))
                        }
                    }

                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    size = geo.size
                                }
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: segment.id)

                    .position(
                        x: segment.position.x + dragOffset.width,
                        y: segment.position.y + dragOffset.height
                    )
                    .gesture(
                        
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                let rawX = segment.position.x + value.translation.width
                                let rawY = segment.position.y + value.translation.height
                                
                                let clampedX = min(max(size.width / 2, rawX), previewSize.width - size.width / 2)
                                let clampedY = min(max(size.height / 2, rawY), previewSize.height - size.height / 2)
                                
                                onMove(CGPoint(x: clampedX, y: clampedY))
                            }
                    )
                    
            }
            
            
            
           

        }
        
        
           
        
    }
    
    
    
}
struct TextSegmentStyleModifier: ViewModifier {
    let segment : TextSegment

    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(segment.alignment.textAlignment)

            .foregroundStyle(Color(segment.textColor.color).opacity((segment.textColor.actualOpacity)))
            .customeStrok(color: Color(segment.textWrapping?.color ?? .clear), lineWidth: segment.textWrapping?.actualStrokeWidth ?? 0)
            .font(Font.custom(segment.font?.fontName ?? "", size: segment.fontSize))
            .padding(.vertical,0)
            .padding(.horizontal,0)
            .shadow(
                color: Color(uiColor: segment.shadow?.color ?? .white).opacity(Double(segment.shadow?.actualOpacity ?? 1) ),
                radius: CGFloat(segment.shadow?.actualRadius ?? 0),
                x: segment.shadow?.angle.offset(with: Double(segment.shadow?.actualOffset ?? 0) ).width ?? 0,
                y: segment.shadow?.angle.offset(with: Double(segment.shadow?.actualOffset ?? 0)).height ?? 0
            )
            .background(Color(segment.backgroundColor?.color ?? .clear).opacity((Double(segment.backgroundColor?.actualOpacity ?? 100) )))
            .opacity(segment.actualOpacity)
            
    }
}
extension View {
    func textSegmentStyle(segment : TextSegment) -> some View {
        modifier(TextSegmentStyleModifier(segment: segment))
    }
}
struct StrokeModifier: ViewModifier {
    var strokeSize: CGFloat = 1
    var strokeColor: Color = .blue
    let id = UUID()
    func body(content: Content) -> some View {
        content
            .padding(strokeSize)
            .background(
                Rectangle()
                    .foregroundStyle(strokeColor)
                    .mask(outline(context: content))
            )
    }
    
    private func outline(context: Content) -> some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            context.drawLayer { layer in
                if let text = context.resolveSymbol(id: id) {
                    layer.draw(text, at: CGPoint(x: size.width / 2, y: size.height / 2))
                }
            }
        } symbols: {
            context.tag(id).blur(radius: strokeSize)
        }
    }
}
extension View {
    func customeStrok(color: Color, lineWidth: CGFloat) -> some View {
        self.modifier(StrokeModifier(strokeSize: lineWidth/5, strokeColor: color))
    }
}
#Preview {
    VStack{
        let textWrapping : TextSegmentWrapping? = TextSegmentWrapping(color: .blue, thickness: 100)
        let shadow = TextSegmentShadow(color: .green, angle: .bottom,opacity: 100,radius: 0, offset: 100)
        let background = TextSegmentColor(color: .black, opacity: 100)

        let segment = TextSegment(content: "Test test test test test test test test test est test test test test t est test test test test t", startTime: 22, duration: 444,backgroundColor: background,shadow: shadow,textWrapping: textWrapping,position: .init(x: 100, y: 200))
        
        
        TextSegmentContentView(segment: segment,previewSize: VideoSize.square1_1.size,isSelected : true,isPreviewPlaying : false) { _ in
            
        }
    }
    .frame(width: 400,height: 400)
    .background(Color.white)
}
