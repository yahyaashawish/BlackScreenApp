//
//  DeleteSegmentTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 13/07/2025.
//
import SwiftUI

struct ExitMontageSheet: View {
    @Environment(\.dismiss) var dismiss
    let appPath = AppPath.shared
    let exitAction : () -> Void
    var body: some View {
        VStack{
            Spacer()

            VStack{

                Text("You are about to leave the video montage, Are you sure you want to leave?")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                
                HStack(spacing:15){
                    Spacer()
                    Button{
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            exitAction()
                        }
                    }label: {
                        Text("Exit")
                            .foregroundStyle(Color("16161D"))
                            .font(.hevay16)
                            .padding(.vertical,10)
                            .padding(.horizontal,40)
                            .background(Color("FF385C"))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    Button{
                        dismiss()
                    }label: {
                        Text("Cancel Command")
                            .foregroundStyle(Color("16161D"))
                            .font(.hevay16)
                            .padding(.vertical,10)
                            .padding(.horizontal,30)
                            .background(Color("C3C3D8"))
                            .clipShape(RoundedRectangle(cornerRadius: 15))


                    }
                    Spacer()
                }

            }
            .padding(20)
            Spacer()

        }
        .background(Color("27272F"))
        
    }
    
}

#Preview {
    ExitMontageSheet(){
        
    }
    
}

