//
//  TransitionTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//


import SwiftUI
struct TransitionTabView: View {
    @Binding var textSegment : TextSegment
    let applyOnAll : (TextTransitionType) -> Void
    var body: some View {
        VStack{
            HStack{
                Text("Text Transition")
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                
                Spacer()
                ApplyOnAllButton {
                    applyOnAll(textSegment.transitionType)

                }
                
                
            }
            .padding(.all,20)
            ScrollView(.horizontal, showsIndicators: false){
                HStack(alignment:.center,spacing:20){
                    ForEach(TextTransitionType.allCases, id: \.self) { type in
                        if type.icon != ""{
                            Button {
                                textSegment.transitionType = type
                            } label: {
                                Image(type.icon)
                                    .foregroundStyle(textSegment.transitionType == type ?  Color("4A4AFF"):Color(.white))
                                
                            }
                        }
                        
                    }
                }
                .padding(.leading,20)
                
                
            }
            
            ResetButton{
                textSegment.transitionType = .none
                
            }
            .padding(.horizontal,20)
            .padding(.vertical,20)
            
        }
        .background(Color("27272F"))
    }
}
