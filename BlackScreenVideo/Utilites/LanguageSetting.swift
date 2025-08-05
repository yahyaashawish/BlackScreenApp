
import SwiftUI

enum AppLanguage : String {
    case en
    case ar
}

@Observable
class LanguageSetting {
    
    static let shared = LanguageSetting()
    var locale = Locale(identifier: "ar")
    
    
    private init(locale: Locale = Locale(identifier: "ar")) {
        self.locale = locale
    }
    
     var isRightToLeft: Bool {
         if getCurrentLanguage() == .ar {
            return true
        }
        return false
    }
    
     func setLocaleArabic() {
        let language = "ar"
        self.locale = Locale(identifier: "ar")
        UserDefaults.standard.set(language, forKey: "language")
        
    }
    
     func setLocaleEnglish() {
        let language = "en"
        self.locale = Locale(identifier: "en")
        UserDefaults.standard.set(language, forKey: "language")
        
    }
    
     func getStoredLanguage() -> AppLanguage? {
        if let language = UserDefaults.standard.string(forKey: "language") {
            self.locale = Locale(identifier: language)
            if language == "ar" {
                return .ar
            }else{
                return .en
            }
        }
        return nil
    }
    
    func getCurrentLanguage() -> AppLanguage {
        if locale.identifier.contains("ar") {
            return .ar
        }else{
            return .en
        }
    }
    
}
