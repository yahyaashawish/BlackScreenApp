
import SwiftUI


class UserIdentifier {
    
    static let shared = UserIdentifier()
    


    
     func setIdentifier() {
         guard getIdentifier() == nil else {             
             return
         }
         
        let user_id = generateGlobalUniqueInt()
        UserDefaults.standard.set(user_id, forKey: "user_identifer")
        
    }

    
     func getIdentifier() -> Int64? {
        if let user_id = UserDefaults.standard.string(forKey: "user_identifer") {
            return Int64(user_id)
        }
        return nil
    }
    
    func clearIdentifer() {
        UserDefaults.standard.removeObject(forKey: "user_identifer")
    }
    func generateGlobalUniqueInt() -> UInt64 {
        let timePart = UInt64(Date().timeIntervalSince1970)
        let randomPart = UInt64.random(in: 0...9999)
        return (timePart * 10_000 + randomPart) % 100_000_000 // max 8 digits
    }
    
}
