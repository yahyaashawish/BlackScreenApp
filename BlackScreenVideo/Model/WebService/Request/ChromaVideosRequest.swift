//
//  FontRequest.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 18/02/2025.
//

import Foundation
class ChromaVideosRequest {
    static let shared = ChromaVideosRequest()
    private init() {}
    private let baseURL = "https://blackscreen.backendiosapp.com/api/get_chroma_videos"
    private var locale : String? {
        LanguageSetting.shared.getStoredLanguage()?.rawValue
    }
    // Fetch all folders
    func fetchVideos(page : Int = 1,completion: @escaping (Result<ChromaVideosResponse, Error>) -> Void) -> URLSessionDataTask?{
        guard let url = URL(string: "\(baseURL)?page_number=\(page)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return nil
        }
        var request = URLRequest(url: url)
        request.addValue(locale ?? "en", forHTTPHeaderField: "language")

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
                let videosResponse = try JSONDecoder().decode(ChromaVideosResponse.self, from: data)
                completion(.success(videosResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }


}
