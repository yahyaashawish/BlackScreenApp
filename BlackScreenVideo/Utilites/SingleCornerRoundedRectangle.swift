//
//  SingleCornerRoundedRectangle.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 31/05/2025.
//

import SwiftUI
struct SingleCornerRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}
