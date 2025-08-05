//
//  TextSegmentRenderer.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 15/07/2025.
//


import SwiftUI

class TextSegmentContentRenderer {
    static func attributedText(from segment: TextSegment,with scale:CGFloat) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: segment.content)
        let fullRange = NSRange(location: 0, length: segment.content.count)
        
        
        // Font
        if let font = segment.font?.uiFont(size: segment.fontSize / scale) {
            attr.addAttribute(.font, value: font, range: fullRange)
        }else{
            let font = UIFont.systemFont(ofSize: segment.fontSize / scale)
            attr.addAttribute(.font, value: font, range: fullRange)

        }

        // Text Color
        attr.addAttribute(.foregroundColor, value: segment.textColor.color.withAlphaComponent(segment.textColor.actualOpacity * segment.actualOpacity), range: fullRange)

        // Background Color
        if let bg = segment.backgroundColor {
            attr.addAttribute(.backgroundColor, value: bg.color.withAlphaComponent(bg.actualOpacity * segment.actualOpacity), range: fullRange)
        }

        // Shadow
        if let shadow = segment.shadow {
            let nsShadow = makeNSShadow(from: shadow,segmentOpacity : segment.actualOpacity,scale: scale)
            attr.addAttribute(.shadow, value: nsShadow, range: fullRange)
        }

        // Text Wrapping (stroke effect)
        if let wrap = segment.textWrapping {
            attr.addAttribute(.strokeColor, value: wrap.color.withAlphaComponent(segment.actualOpacity), range: fullRange)
            attr.addAttribute(.strokeWidth, value: -wrap.actualStrokeWidth, range: fullRange)
        }

        // Alignment
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = {
            switch segment.alignment {
            case .left: return .left
            case .center: return .center
            case .right: return .right
            }
        }()
        attr.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

        return attr
    }
    
    static func makeNSShadow(from shadow: TextSegmentShadow,segmentOpacity : CGFloat,scale: CGFloat) -> NSShadow {
        let nsShadow = NSShadow()
        
        // Set blur radius (matches SwiftUI shadow radius)
        nsShadow.shadowBlurRadius = shadow.actualRadius * 10
        
        // Set shadow color with opacity
        nsShadow.shadowColor = shadow.color.withAlphaComponent(shadow.actualOpacity * segmentOpacity)
        
        // Set offset based on direction and magnitude
        let offset = shadow.angle.offset(with: shadow.actualOffset / scale)
        nsShadow.shadowOffset = CGSize(width: offset.width, height: -offset.height) // Invert Y for CoreText drawing
        
        return nsShadow
    }
}
extension LocalFont {
    func uiFont(size: CGFloat) -> UIFont {
        UIFont(name: name ?? "", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
