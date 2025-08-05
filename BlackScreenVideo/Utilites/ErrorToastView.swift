//
//  ErrorToastView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/07/2025.
//

import SwiftUI
struct ErrorToastView: View {
    let message: LocalizedStringKey
    let retryAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

            Text(message)
                .font(.medium12)
                .foregroundColor(.white)
                .font(.footnote)
                .lineLimit(2)
            
            
            Button{
                retryAction()
            }label: {
                Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.bold13)
                    .foregroundStyle(Color("primary-color"))
            }
            
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.3))
            .clipShape(.circle)
        }
        .padding(12)
        .background(Color("FF385C").opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .white,radius: 3)
        
    }
}
#Preview {
    ErrorToastView(message: "Test error mesage") {
        
    }
}
