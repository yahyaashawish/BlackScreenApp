//
//  CustomBackButtonView.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 11/11/2024.
//


import SwiftUI
struct AppBackButton: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let action : (()->Void)?
    init(){
        self.action = nil
    }

    init(action : @escaping ()->Void){
        self.action = action
        
    }
    var body: some View {
        Button{
            if let action = self.action {
                action()
            }else{
                dismiss()
            }
        }label: {
            if layoutDirection == .rightToLeft {
                Image(.back)
                    .frame(width: 30,height: 30)
            }else{
                Image(.back)
                    .frame(width: 30,height: 30)
                    .rotationEffect(.degrees(180))
            }
            
            
        }
    }
}

#Preview {
    AppBackButton()
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
    
    
}
