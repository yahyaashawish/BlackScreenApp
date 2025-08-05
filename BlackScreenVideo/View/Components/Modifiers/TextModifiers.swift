//
//  Untitled.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 06/11/2024.
//
import SwiftUI

struct HeaderTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("ALEXANDRIA-REGULAR", size: 24, relativeTo: .title))
    }
}

struct SubHeaderTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("ALEXANDRIA-BOLD", size: 14, relativeTo: .title))
            .foregroundStyle(Color.black)
    }
}



struct TextFieldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("ALEXANDRIA-MEDIUM", size: 14, relativeTo: .title))
            .foregroundStyle(.black)
    }
}

struct TabBarTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("ALEXANDRIA-REGULAR", size: 10, relativeTo: .title))
    }
}


extension View {

    func headerTextModifier() -> some View {
        self.modifier(HeaderTextStyle())
    }
    func subHeaderTextModifier() -> some View {
        self.modifier(SubHeaderTextStyle())
    }
    
   
    func textFieldTextModifier() -> some View {
        self.modifier(TextFieldTextStyle())
    }
    
    func tabBarTextModifier() -> some View {
        self.modifier(TabBarTextStyle())
    }
    
    
    
}
