import SwiftUI

struct ChooseVideoSizeSheet: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var sizeSelection: VideoSize?
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                Color.clear.ignoresSafeArea()
                VStack{
                    VStack{
                        HStack{
                            Spacer()
                            Text("Choose video size")
                                .font(.bold13)
                                .foregroundStyle(Color("6C6C7B"))
                                .padding(.top,15)
                            Spacer()
                        }
                        Divider()
                        ScrollView{
                        ForEach(VideoSize.allCases , id: \.self) { size in
                                VStack{
                                    Button {
                                        sizeSelection = size
                                        dismiss()
                                        
                                    }label:{
                                        HStack{
                                            size.icon
                                                .frame(width: 32, height: 32)
                                            HStack(spacing: 0){
                                                Text(size.description)
                                                    .font(.bold13)
                                                    .foregroundStyle(Color("9191A8"))
                                                Text(size.rawValue)
                                                    .font(.bold18)
                                                    .foregroundStyle(Color("9191A8"))
                                                Text("Size")
                                                    .font(.bold18)
                                                    .foregroundStyle(Color("9191A8"))
                                            }
                                            Spacer()
                                        }
                                    }
                                    .padding(.horizontal,20)
                                    Divider()
                                }
                            }
                        }
                    }
                    .background(Color("1B1B22"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    VStack{
                        Button{
                            dismiss()
                        }label: {
                            HStack{
                                Spacer()
                                Text("Cancel")
                                    .font(.bold20)
                                    .foregroundStyle(.white)
                                Spacer()
                            }

                        }
                        .padding(.vertical,15)

                    }
                    .background(Color("1B1B22"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(10)
            }
            
            
        }
        .onAppear{
            sizeSelection = nil
            
        }
        .navigationBarBackButtonHidden(true)
        
    }
    
    
    
    
    
    
    
    
}









#Preview {
    ChooseVideoSizeSheet(sizeSelection: .constant(nil))
    .environment(\.locale, .init(identifier: "ar"))
    .environment(\.layoutDirection,  .rightToLeft )
    
}




