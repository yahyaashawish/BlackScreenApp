//
//  func.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 25/01/2025.
//
import SwiftUI

extension UIImage {
    
    static func createTopBorderLine(color: UIColor, height: CGFloat) -> UIImage {
        let size = CGSize(width: 1, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toFit size: CGSize) -> UIImage? {
        let aspectWidth = size.width / self.size.width
        let aspectHeight = size.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        let newSize = CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        return resized(to: newSize)
    }
}
