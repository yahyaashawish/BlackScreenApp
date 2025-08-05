//
//  String.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 16/02/2025.
//
import SwiftUI
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(_ args: CVarArg...) -> String {
        let localizedString = NSLocalizedString(self, comment: "")
        return String(format: localizedString, arguments: args)
    }
}
