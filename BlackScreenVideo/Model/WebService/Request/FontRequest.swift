//
//  FontRequest.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//



import Foundation

struct FontRequest {
    
    static let shared = FontRequest()
    private init() {}
    
    let baseURL: String =  "https://blackscreen.backendiosapp.com/api/fonts"
    
    func fetchFontsData(page : Int,completion: @escaping (Result<FontResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)?page_number=\(page)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
        
    }


}
