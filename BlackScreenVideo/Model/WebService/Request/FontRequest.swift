//
//  FontRequest.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//



import Foundation

enum FontType : String , CaseIterable{
    case en
    case ar
    
    var title : String {
        switch self {
        case .ar:
            return "العربية"
        case .en:
            return "English"
        }
    }
}

struct FontRequest {
    
    static let shared = FontRequest()
    private init() {}
    private var locale : String? {
        LanguageSetting.shared.getStoredLanguage()?.rawValue
    }
    let baseURL: String =  "https://blackscreen.backendiosapp.com/api/fonts"
   
    func fetchFontsData(page : Int,type : FontType,completion: @escaping (Result<FontResponse, Error>) -> Void) -> URLSessionDataTask?{
        guard let url = URL(string: "\(baseURL)?page_number=\(page)&type=\(type.rawValue)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return nil
        }
        var request = URLRequest(url: url)
        request.addValue(locale ?? "en", forHTTPHeaderField: "language") // 👈 Language header

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                    return
                }
                
                do {
                    let fonts = try JSONDecoder().decode(FontResponse.self, from: data)
                    completion(.success(fonts))
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
            return task

    }


}
