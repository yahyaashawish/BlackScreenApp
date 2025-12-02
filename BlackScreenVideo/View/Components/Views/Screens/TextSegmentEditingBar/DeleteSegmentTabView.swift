//
//  OpacityTabView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
enum SegmentType {
    case text
    case media
}
struct DeleteSegmentTabView: View {
    let segmentType:SegmentType
    let action:()->Void
    let cancelAction:()->Void
    var body: some View {
        VStack{
            VStack{
                Text(segmentType == .text ? "Are you sure that you are want to delete this text clip ?" : "Are you sure that you are want to delete this media clip ?")
                    .foregroundStyle(Color("9191A8"))
                    .font(.medium16)
                
                HStack(spacing:15){
                    Spacer()
                    Button{
                        action()
                    }label: {
                        Text("Confirm Delete")
                            .foregroundStyle(Color("16161D"))
                            .font(.hevay16)
                            .padding(10)
                            .background(Color("FF385C"))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    Button{
                        cancelAction()
                    }label: {
                        Text("Cancel Command")
                            .foregroundStyle(Color("16161D"))
                            .font(.hevay16)
                            .padding(10)
                            .background(Color("C3C3D8"))
                            .clipShape(RoundedRectangle(cornerRadius: 15))


                    }
                    Spacer()
                }
            }
            .padding(20)
            
        }
        .background(Color("27272F"))

        
    }
    
}

#Preview {
    DeleteSegmentTabView(segmentType: .media, action: {
        
    }, cancelAction: {
        
    })
    .background(Color("27272F"))

}
