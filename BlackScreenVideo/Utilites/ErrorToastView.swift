//
//  ErrorToastView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/07/2025.
//

import SwiftUI
struct ErrorToastView: View {
    let error : AppError?
    let retryAction: (() -> Void)?

    var body: some View {
        if let error  = error {
            HStack(spacing: 10) {
                
                error.icon
                
                VStack(alignment:.center){
                    HStack{
                        Text(error.title)
                            .font(.medium12)
                            .foregroundColor(.black)
                            .font(.footnote)
                            .lineLimit(1)
                        
                        if let retryAction {
                            Button{
                                retryAction()
                            }label: {
                                Text("Retry")
                                    .font(.medium14)
                                    .foregroundStyle(Color("4A4AFF"))
                                    .underline(true, color: Color("4A4AFF"))
                                
                            }
                        }
                        
                        
                    }
                    if error.message != "" {
                        Text(error.message)
                            .font(.medium10)
                            .foregroundColor(.black)
                            .font(.footnote)
                            .lineLimit(1)
                    }
                    
                    
                }
                
                
                Button{
                    ErrorHandler.shared.dismissError()
                }label: {
                    Image(systemName: "xmark")
                        .font(.medium14)
                        .foregroundStyle(.black)
                }
                
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(.circle)
            }
            .padding(12)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: .white,radius: 3)
        }
        else{
            EmptyView()
        }
        
    }
}
#Preview {
    ErrorToastView(error:.fetchVideosFailed) {
        
    }
}
