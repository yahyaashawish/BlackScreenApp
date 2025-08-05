
import SwiftUI

struct ContentView: View {
    @ObservedObject var appPath = AppPath.shared
    @Environment(LanguageSetting.self) private var languageSetting
    var body: some View {
        NavigationStack(path: $appPath.path) {
            GeometryReader{ geometry in
                ZStack(alignment: .center){
                    AppBackground()
                    BackgroundPatternImages()
                    
                    VStack(alignment: .leading){
                        Image("app-logo")
                            .resizable()
                            .frame(width: 290,height: 355)
                            .padding(.bottom,80)
                        Text("Design Black Screen Video")
                            .font(.medium24)
                            .foregroundStyle(.white)
                        Text("Simply")
                            .font(.hevay30)
                            .foregroundStyle(.white)
                        
                        HStack(spacing:20){
                            Button{
                                languageSetting.setLocaleEnglish()
                                appPath.navigate(to: .mainView)
                            }label: {
                                HStack{
                                    Image("arrow")
                                    Spacer()
                                    Text("English")
                                        .font(.bold18)
                                        .foregroundStyle(.white)
                                        .padding(.trailing,5)
                                }
                                .padding(10)
                                .background(Color("secondry-color"))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .frame(width: 130)
                            }
                            Button{
                                languageSetting.setLocaleArabic()
                                appPath.navigate(to: .mainView)

                            }label: {
                                HStack{
                                    Text("عربي")
                                        .font(.bold18)
                                        .foregroundStyle(.white)
                                        .padding(.leading,5)
                                    
                                    Spacer()
                                    
                                    Image("arrow")
                                        .rotationEffect(.degrees(180))
                                    
                                }
                                .padding(10)
                                .background(Color("primary-color"))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .frame(width: 130)
                                
                            }
                        }
                        .environment(\.layoutDirection, .rightToLeft)
                        
                        
                    }
                    .frame(width: geometry.size.width)
                    .padding(.vertical,60)
                    
                }
            }
            .interfaceOrientations(.portrait)
            .appDestinationRouteModifier()
        }
        
         .onAppear{
                 languageSetting.setLocaleArabic()
            
        }
    }
    
    
}








#Preview {
    ContentView()
        .environment(LanguageSetting.shared)
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection,  .rightToLeft )
    
}

struct BackgroundPatternImages: View {
    var body: some View {
        VStack{
            HStack{
                Image("top-pattern")
                Spacer()
            }
            Spacer()
            HStack{
                Spacer()
                Image("bottom-pattern")
            }
        }
        .ignoresSafeArea()
        .environment(\.layoutDirection, .rightToLeft)

    }
}
