
import SwiftUI

enum AppLanguage : String {
    case en
    case ar
}

@Observable
class LanguageSetting {
    
    static let shared = LanguageSetting()
    var locale: Locale
    
    
    private init() {
        let storedLanguage = UserDefaults.standard.string(forKey: "language")
        let language = AppLanguage(rawValue: storedLanguage ?? "") ?? .ar
        self.locale = Locale(identifier: language.rawValue)
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
        guard let language = UserDefaults.standard.string(forKey: "language") else {
            return nil
        }
        return AppLanguage(rawValue: language)
    }
    
    func getCurrentLanguage() -> AppLanguage {
        if locale.identifier.contains("ar") {
            return .ar
        }else{
            return .en
        }
    }
    
}
