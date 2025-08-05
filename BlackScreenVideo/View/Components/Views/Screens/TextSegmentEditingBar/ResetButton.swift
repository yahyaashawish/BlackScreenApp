//
//  ResetButton.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
struct ResetButton: View {
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("474755"))
                .frame(height: 36)
                .overlay {
                    Image("reset-icon")
                }
        }
        
    }
}
