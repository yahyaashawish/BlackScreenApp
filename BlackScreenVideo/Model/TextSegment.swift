import SwiftUI
struct TextSegment: Identifiable, Equatable {
    let id: UUID
    var content: String
    var startTime: TimeInterval
    var duration: TimeInterval
    var endTime: TimeInterval {
        startTime + duration
    }
    var trackIndex: Int
    

    // Style properties
    var font: LocalFont?
    var alignment: TextSegmentAlignment
    var fontSize: CGFloat
    var textColor: TextSegmentColor
    var backgroundColor: TextSegmentColor?
    let maxOpacity = PropertiesConstants.MaximumOpacity

    private var internalOpacity: Double
    var opacity: Double {
        get {
            return ( internalOpacity / maxOpacity ) * 100
        }
        set {
            internalOpacity = ( newValue / 100 ) * maxOpacity
        }
    }
    var actualOpacity: CGFloat {
        internalOpacity
    }
    var shadow: TextSegmentShadow?
    var textWrapping: TextSegmentWrapping?
    var transitionType: TextTransitionType
    
    // Position in video (absolute or relative, based on your rendering logic)
    var position: CGPoint  // e.g., CGPoint(x: 100, y: 200)
    
    
    init(
        id: UUID = UUID(),
        content: String,
        startTime: TimeInterval,
        duration: TimeInterval,
        trackIndex: Int = 0,
        font: LocalFont? = nil,
        alignment: TextSegmentAlignment = .center ,
        fontSize: CGFloat = 16,
        textColor: TextSegmentColor = TextSegmentColor(color: UIColor(resource: .palette2), opacity: 100),
        backgroundColor: TextSegmentColor? = nil,
        opacity: Double = 100,
        shadow: TextSegmentShadow? = nil,
        textWrapping: TextSegmentWrapping? = nil,
        transitionType: TextTransitionType = .none,
        position: CGPoint = .zero
    ) {
        self.id = id
        self.content = content
        self.startTime = startTime
        self.duration = duration
        self.trackIndex = trackIndex
        self.font = font
        self.alignment = alignment
        self.fontSize = fontSize
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.internalOpacity = ( opacity / 100 ) * maxOpacity
        self.shadow = shadow
        self.textWrapping=textWrapping
        self.transitionType = transitionType
        self.position = position
    }
    
 
}
struct TextSegmentColor : Equatable{
    var color: UIColor
    private var internalOpacity: Double
    
    let maxOpacity = PropertiesConstants.MaximumOpacity
    init(color: UIColor, opacity: Double) {
        self.internalOpacity = ( opacity / 100 ) * maxOpacity
        self.color = color
    }
    var opacity: Double {
        get {
            return ( internalOpacity / maxOpacity ) * 100
        }
        set {
            internalOpacity = ( newValue / 100 ) * maxOpacity
        }
    }
    var actualOpacity: CGFloat {
        internalOpacity
    }
}

enum SegmentColorType {
    case text
    case background
    
    var title: LocalizedStringKey {
        switch self {
        case .text:
            return "Text Color"
        case .background:
            return "Background Color"
        }
    }
}
struct TextSegmentShadow : Equatable {
    var color: UIColor
    var angle: ShadowAngle
    private var internalOpacity: Double
    let maxOpacity = PropertiesConstants.MaximumOpacity
    private var internalRadius: Double
    let maxRadius = PropertiesConstants.MaximumShadowRadius
    private var internalOffset: CGFloat
    let maxOffset = PropertiesConstants.MaximumShadowOffset

    
    init(color: UIColor, angle: ShadowAngle, opacity: Double,radius: Double, offset: Double) {
        self.color = color
        self.angle = angle
        self.internalOpacity = ( opacity / 100 ) * maxOpacity
        self.internalRadius = ( radius / 100 ) * maxRadius
        self.internalOffset = ( offset / 100 ) * maxOffset
    }
    var opacity: Double {
        get {
            return ( internalOpacity / maxOpacity ) * 100
        }
        set {
            internalOpacity = ( newValue / 100 ) * maxOpacity
        }
    }
    var actualOpacity: CGFloat {
        internalOpacity
    }
    var radius: Double {
        get {
            return ( internalRadius / maxRadius ) * 100
        }
        set {
            internalRadius = ( newValue / 100 ) * maxRadius
        }
    }
    var actualRadius: CGFloat {
        internalRadius
    }
    
    var offset: Double {
        get {
            return ( internalOffset / maxOffset ) * 100
        }
        set {
            internalOffset = ( newValue / 100 ) * maxOffset
        }
    }
    var actualOffset: CGFloat {
        internalOffset
    }
    
    
}
enum TextSegmentAlignment : CaseIterable, Equatable {
    case left
    case center
    case right
    
    var textAlignment: TextAlignment {
        switch self {
        case .left:
                .leading
        case .center:
                .center
        case .right:
                .trailing
        }
    }
    
    var icon : String {
        switch self {
        case .left:
            "text.alignleft"
        case .center:
            "text.aligncenter"
        case .right:
            "text.alignright"
        }
    }
}
struct TextSegmentWrapping: Equatable {
    var color: UIColor
    
    // Store scaled thickness (0 to 5)
    private var internalThickness: CGFloat
    
    let maxThickness: CGFloat = PropertiesConstants.MaximumTextWrapperThikness
    // Public initializer accepts 0–100
    init(color: UIColor, thickness: CGFloat) {
        self.color = color
        self.internalThickness = (thickness / 100.0) * maxThickness
    }
    
    // Public getter/setter for 0–100 value
    var thickness: CGFloat {
        get {
            return (internalThickness / maxThickness) * 100.0
        }
        set {
            internalThickness = (newValue / 100.0) * maxThickness
        }
    }
    
    // Internal use only, gives actual scaled value (0–5)
    var actualStrokeWidth: CGFloat {
        internalThickness
    }
}
enum ShadowAngle: CaseIterable ,Equatable{
    case topRight
    case top
    case topLeft
    
    case centerRight
    case center
    case centerLeft
    
    case bottomRight
    case bottom
    case bottomLeft
    
    var alignment: Alignment {
        switch self {
        case .topRight:
               return .topTrailing
        case .top:
            return .top
        case .topLeft:
            return .topLeading
            
        case .centerRight:
            return .trailing
        case .center:
            return .center
        case .centerLeft:
            return .leading
            
        case .bottomRight:
            return .bottomTrailing
        case .bottom:
            return .bottom
        case .bottomLeft:
            return .bottomLeading
        }
    }
    
    func offset(with magnitude: Double) -> CGSize {
        switch self {
        case .topLeft: return CGSize(width: -magnitude, height: -magnitude)
        case .top: return CGSize(width: 0, height: -magnitude)
        case .topRight: return CGSize(width: magnitude, height: -magnitude)
        case .centerLeft: return CGSize(width: -magnitude, height: 0)
        case .center: return CGSize(width: 0, height: 0)
        case .centerRight: return CGSize(width: magnitude, height: 0)
        case .bottomLeft: return CGSize(width: -magnitude, height: magnitude)
        case .bottom: return CGSize(width: 0, height: magnitude)
        case .bottomRight: return CGSize(width: magnitude, height: magnitude)
        }
    }
    
    
    
}

