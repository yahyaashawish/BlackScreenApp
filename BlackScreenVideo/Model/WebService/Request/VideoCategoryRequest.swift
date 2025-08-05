//
//  FontRequest.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 18/02/2025.
//

import Foundation
class VideoCategoryRequest {
    static let shared = VideoCategoryRequest()
    private init() {}
    private let categoriesURL = "https://blackscreen.backendiosapp.com/api/videos/categories"
    private let categoryVideosURL = "https://blackscreen.backendiosapp.com/api/videos/category/"
    private var locale : String? {
        LanguageSetting.shared.getStoredLanguage()?.rawValue
    }
    // Fetch all folders
    func fetchCatgories(completion: @escaping (Result<VideoCategoryResponse, Error>) -> Void) -> URLSessionDataTask?{
        guard let url = URL(string: "\(categoriesURL)") else {
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
                completion(.failure(NSError(domain: "No data", code: 404, userInfo: nil)))
                return
            }
            
            do {
                let categoriessResp = try JSONDecoder().decode(VideoCategoryResponse.self, from: data)
                completion(.success(categoriessResp))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }
    
    func fetchCatgoryVideos(for id : Int,completion: @escaping (Result<CategoryVideosResponse, Error>) -> Void) -> URLSessionDataTask?{
        guard let url = URL(string: "\(categoryVideosURL)\(id)") else {
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
                completion(.failure(NSError(domain: "No data", code: 404, userInfo: nil)))
                return
            }
            
            do {
                let videosResp = try JSONDecoder().decode(CategoryVideosResponse.self, from: data)
                completion(.success(videosResp))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }


}
