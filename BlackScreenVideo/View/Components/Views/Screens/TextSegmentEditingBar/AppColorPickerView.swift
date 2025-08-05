//
//  AppColorPickerView.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 21/06/2025.
//

import SwiftUI
struct AppColorPickerView: View {
    @State private var selectedCustomColor : Color = .accentColor
    @State private var selectedPlatteColor : UIColor? = nil
    @Binding var selectedColor: UIColor?
    var body: some View {
        HStack{
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(alignment:.top,spacing:5){
                    VStack{
                        HStack {
                            ZStack{
                                if selectedPlatteColor == nil && selectedCustomColor != .accentColor {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(selectedCustomColor)
                                        .frame(width: 24, height: 36)
                                }else{
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(
                                            AngularGradient(
                                                gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]),
                                                center: .center
                                            )
                                        )
                                        .frame(width: 24, height: 36)
                                }
                                
                                
                                Image("plus")
                                
                            }
                            .overlay{
                                ColorPicker("", selection: $selectedCustomColor,
                                            supportsOpacity: false)
                                .labelsHidden()
                                .blur(radius: 100)
                                .frame(width : 24, height: 36)
                                .clipped()
                            }
                            
                            
                        }
                        if selectedPlatteColor == nil && selectedCustomColor != .accentColor {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.white)
                                .frame(width: 7, height: 3)
                        }
                    }
                    
                    
                    ForEach(PropertiesConstants.ColorPalettes, id: \.self) { platte in
                        VStack{
                            Button {
                               
                                selectedColor = platte

                                    selectedPlatteColor = platte

                                
                            } label: {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color(platte))
                                    .frame(width :24,height: 36)
                                
                            }
                            if selectedPlatteColor == platte{
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white)
                                    .frame(width: 7, height: 3)
                            }
                            
                            
                            Spacer()
                            
                            
                        }
                        .frame(height:60)
                        
                    }
                }
                
                
            }
        }
        .onChange(of: selectedCustomColor) { oldValue , newValue in
                selectedColor = UIColor(newValue)
                selectedPlatteColor = nil
        }
        .onChange(of: selectedColor) { oldValue , newValue in
            if newValue == nil {
                selectedPlatteColor = nil
                selectedCustomColor = .accentColor

            }
        }
        .onAppear{
            determineSelectedColor()
        }
        
    }
    func determineSelectedColor() {
        if let selectedColor {
            selectedCustomColor = Color(selectedColor)
            for color in PropertiesConstants.ColorPalettes {
                if color == selectedColor {
                    selectedPlatteColor = color
                    selectedCustomColor = .accentColor
                    break
                }
            }
        }
        
    }
}
