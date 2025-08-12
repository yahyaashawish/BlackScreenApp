//
//  FontManager.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//


import Foundation
import SwiftUI
import SwiftData
import CoreText


class FontManager {
    static let shared = FontManager()
    
    func registerFontIfNeeded(for fontName: String) -> Bool {
        
        let fileName = fontName + ".ttf"
        let url = getLocalFontURL(fontName: fileName)
        
        
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let fontName = CTFontDescriptorCopyAttribute(descriptors[0], kCTFontNameAttribute) as? String else {
            return false
        }
        
        // Check if the font is already available
        if let _ = UIFont(name: fontName, size: 16) {
            return true
        }
        
        // Register the font
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            print("font file registerd from url: \(url) with name \(fontName)")

            return true
        } else {
            print("Failed to register font: \(error?.takeUnretainedValue().localizedDescription ?? "")")
            return false
        }
    }
    
    
    func downloadAndRegisterFont(from fontURLString: String, fontName: String, completion: @escaping (Bool, URL?) -> Void) -> URLSessionDownloadTask? {
        let fileName = fontName + ".ttf"
                let fileURL = getLocalFontURL(fontName: fileName)
        
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let register = registerFontIfNeeded(for: fontName)
                    completion(register, fileURL)
                    return nil
                }
        
                guard let url = URL(string: fontURLString) else {
                    completion(false, nil)
                    return nil
                }
        
                let task = URLSession.shared.downloadTask(with: url) { location, _, _ in
                    guard let location = location else {
                        completion(false,nil)
                        return
                    }
        
                    do {
                        try FileManager.default.moveItem(at: location, to: fileURL)
                        print("font file downloaded on local path: \(fileURL.path)")
                        let register = self.registerFontIfNeeded(for: fontName)
                        completion(register, fileURL)

                    } catch {
                        print("Error saving font: \(error)")
                        completion(false,nil)
                    }
                }
                task.resume()
                return task
    }
    
        func getLocalFontURL(fontName: String) -> URL {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return docs.appendingPathComponent(fontName)
        }
}
//class FontManager {
//    static let shared = FontManager()
//
//    func downloadFont(from urlString: String, fontName: String, completion: @escaping (UIFont?) -> Void) {
//        let fileName = fontName + ".ttf"
//        let fileURL = getLocalFontURL(fontName: fileName)
//
//        if FileManager.default.fileExists(atPath: fileURL.path) {
//            registerFont(from: fileURL, completion: completion)
//            return
//        }
//
//        guard let url = URL(string: urlString) else {
//            completion(nil)
//            return
//        }
//
//        URLSession.shared.downloadTask(with: url) { location, _, _ in
//            guard let location = location else {
//                completion(nil)
//                return
//            }
//
//            do {
//                try FileManager.default.moveItem(at: location, to: fileURL)
//                self.registerFont(from: fileURL, completion: completion)
//            } catch {
//                print("Error saving font: \(error)")
//                completion(nil)
//            }
//        }.resume()
//    }
//
//    private func registerFont(from url: URL, completion: @escaping (UIFont?) -> Void) {
//        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
//              let fontName = CTFontDescriptorCopyAttribute(descriptors[0], kCTFontNameAttribute) as? String else {
//            completion(nil)
//            return
//        }
//
//        // Check if the font is already available
//        if let existingFont = UIFont(name: fontName, size: 16) {
//            DispatchQueue.main.async {
//                completion(existingFont)
//            }
//            return
//        }
//
//        // Register the font
//        var error: Unmanaged<CFError>?
//        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
//            let registeredFont = UIFont(name: fontName, size: 16)
//            DispatchQueue.main.async {
//                completion(registeredFont)
//            }
//        } else {
//            print("Failed to register font: \(error?.takeUnretainedValue().localizedDescription ?? "")")
//            completion(nil)
//        }
//    }
//

//
//
//
//}
