//
//  FinalVideoButton.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 08/07/2025.
//


import SwiftUI
struct FinalVideoButton: View {
    let title : LocalizedStringKey
    let icon : String
    let action : () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            VStack{
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("27272F"))
                    .frame(width: 95 , height: 72)
                    .overlay {
                            Image(icon)
                    }
                
                Text(title)
                    .font(.regular16)
                    .foregroundStyle(Color("A1A1B9"))
            }
        }
    }
}
