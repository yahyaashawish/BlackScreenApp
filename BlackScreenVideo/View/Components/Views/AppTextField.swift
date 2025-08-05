//
//  AppTextField.swift
//  PicturesLock
//
//  Created by Yahya A Shawish on 14/11/2024.
//
import SwiftUI
struct AppTextField: View {
    
    
    @FocusState private var isFocusedField: Bool
    
    let placeholder: LocalizedStringKey
    @Binding var text: String
    let alignment: TextAlignment
    let keyboardType: UIKeyboardType
    var height : CGFloat = 48
    var bgColor : Color = Color("27272F")
    var placeholderColor : Color = Color("9191A8")
    var radius : CGFloat = 25
    @Binding var isFocused : Bool?
    var submitAction : (() -> Void)?
    let icon : String?
    init(placeholder: LocalizedStringKey, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
        self.alignment = .leading
        self.keyboardType = .default
        _isFocused = .constant(nil)
        self.icon = nil
    }
    init(placeholder: LocalizedStringKey, text: Binding<String>,radius : CGFloat , bgColor : Color,placeholderColor : Color,height : CGFloat,isFocused : Binding<Bool?>) {
        self.placeholder = placeholder
        self._text = text
        self.alignment = .leading
        self.keyboardType = .default
        _isFocused = isFocused
        self.icon = nil
        self.radius = radius
        self.bgColor = bgColor
        self.placeholderColor = placeholderColor
        self.height = height
    }
    init(placeholder: LocalizedStringKey, text: Binding<String>,icon : String?,height: CGFloat,bgColor : Color,isFocused : Binding<Bool?>,submitAction : (() -> Void)?) {
        self.placeholder = placeholder
        self._text = text
        self.alignment = .leading
        self.keyboardType = .default
        self.height = height
        self.bgColor = bgColor
        _isFocused = isFocused
        self.submitAction = submitAction
        self.icon = icon
        
    }
    
    
    var body: some View {
        
        
        RoundedRectangle(cornerRadius: radius)
            .fill(bgColor)
            .frame(height:height)
            .overlay {
                HStack{
                    if let icon = self.icon {
                        Image(icon)
                            .padding(.leading,15)
                    }
                    
                    TextField("", text: $text,prompt: Text(placeholder).foregroundColor(placeholderColor))
                        .frame(height: height+10)
                        .tint(placeholderColor)
                        .foregroundStyle(placeholderColor)
                        .multilineTextAlignment(alignment)
                        .keyboardType(keyboardType)
                        .focused($isFocusedField)
                        .onSubmit {
                            submitAction?() ?? done()
                        }
                        .submitLabel(.done)
                        .padding([.leading, .trailing], 15)
                        .onAppear(){
                            if isFocused == true {
                                self.isFocusedField = true
                            }
                        }
                }
                .contentShape(Capsule())
                .onTapGesture {
                    
                    self.isFocusedField = true
                }
                
            }
            .onTapGesture {
                self.isFocusedField = true
            }
            .onChange(of: isFocusedField) { old , newValue in
                
                self.isFocused = newValue
            }
            .onChange(of: isFocused) { oldValue, newValue in
                if let newValue = newValue  {
                    self.isFocusedField = newValue
                }
                
            }
        
        
    }
    func done(){
        self.isFocusedField = false
    }
    
}

#Preview {
    NavigationStack{
        AppTextField(placeholder: "Enter text here", text: .constant(""))
            .environment(\.locale, .init(identifier: "ar"))
            .environment(\.layoutDirection,  .rightToLeft )
        
    }
    
    
}
