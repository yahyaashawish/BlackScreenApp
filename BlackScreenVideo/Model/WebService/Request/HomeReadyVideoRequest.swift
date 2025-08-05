//
//  FontRequest.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 18/02/2025.
//

import Foundation
class HomeReadyVideoRequest {
    static let shared = HomeReadyVideoRequest()
    private init() {}
    private let baseURL = "https://blackscreen.backendiosapp.com/api/videos/home"
    private var locale : String? {
        LanguageSetting.shared.getStoredLanguage()?.rawValue
    }
    // Fetch all folders
    func fetchVideos(completion: @escaping (Result<HomeReadyVideoResponse, Error>) -> Void) -> URLSessionDataTask?{
        guard let url = URL(string: "\(baseURL)") else {
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
                let videosResponse = try JSONDecoder().decode(HomeReadyVideoResponse.self, from: data)
                completion(.success(videosResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }


}
