//
//  CustomBackButtonToolbarModifier.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 11/11/2024.
//


import SwiftUI


struct TitleToolbarModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme // Detect current mode
    
    let title  : LocalizedStringKey?
    let staticTitle : String?
    let action : (() -> Void)?
    init(title: LocalizedStringKey) {
        self.title = title
        self.staticTitle = nil
        self.action = nil
        
    }

    
    init(staticTitle: String) {
        self.title = nil
        self.staticTitle = staticTitle
        self.action = nil
        
    }
    init(title: LocalizedStringKey,action:  (() -> Void)?) {
        self.title = title
        self.staticTitle = nil
        self.action = action
        
    }
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack{
                        if  let action  = action {
                            
                            AppBackButton{
                                action()
                            }
                        }else{
                                AppBackButton()
                                
                          
                        }
                        
                        if staticTitle != nil {
                                Text(staticTitle!)
                                    .font(Font.medium24)
                                    .foregroundStyle(Color("C3C3D8"))
                            
                        }else{
                                Text(title!)
                                    .font(Font.medium24)
                                    .foregroundStyle(Color("C3C3D8"))

                            
                            
                        }
                        
                        Spacer()
                        
                    }
                    
                }
                
                
            }

        
    }
}






extension View {
    
    
    func titleToolbar( title : LocalizedStringKey) -> some View {
        self.modifier(TitleToolbarModifier(title: title))
    }
    
    func titleToolbar( staticTitle : String) -> some View {
        self.modifier(TitleToolbarModifier(staticTitle: staticTitle))
    }
    func titleToolbar( title : LocalizedStringKey,action : @escaping () -> Void) -> some View {
        self.modifier(TitleToolbarModifier(title: title,action: action))
    }
    
}
