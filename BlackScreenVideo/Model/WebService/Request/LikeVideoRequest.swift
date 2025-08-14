//
//  FontRequest.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 18/02/2025.
//

import Foundation
class LikeVideoRequest {
    static let shared = LikeVideoRequest()
    private init() {}
    private let baseURL = "https://blackscreen.backendiosapp.com/api/user/videos/add_remove_like"
    private var locale : String? {
        LanguageSetting.shared.getStoredLanguage()?.rawValue
    }
    // Fetch all folders
    func toggleVideoLike(videoId : Int ,userId : Int64 ,completion: @escaping (Result<ToggleLikeResponse, Error>) -> Void) -> URLSessionDataTask?{
        guard let url = URL(string: "\(baseURL)/\(videoId)?user_identifier=\(userId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

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
                let statusResponse = try JSONDecoder().decode(ToggleLikeResponse.self, from: data)
                completion(.success(statusResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }


}
