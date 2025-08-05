//
//  FontRequest.swift
//  VideoMaker
//
//  Created by Yahya A Shawish on 18/02/2025.
//

import Foundation
class MusicRequest {
    static let shared = MusicRequest()
    private init() {}
    private let baseURL = "https://blackscreen.backendiosapp.com/api/music"
    private var locale : String? {
        LanguageSetting.shared.getStoredLanguage()?.rawValue
    }
    // Fetch all folders
    func fetchFolders(completion: @escaping (Result<SongsFoldersResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/categories") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(locale ?? "en", forHTTPHeaderField: "language") // 👈 Language header

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 404, userInfo: nil)))
                return
            }
            
            do {
                let foldersRequest = try JSONDecoder().decode(SongsFoldersResponse.self, from: data)
                completion(.success(foldersRequest))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


    // Fetch songs for a specific folder ID
    func fetchSongs(for folderId: Int,page : Int,completion: @escaping (Result<FolderSongsResponse, Error>) -> Void) -> URLSessionDataTask?{
        
        guard let url = URL(string: "\(baseURL)/get_music/\(folderId)?page_number=\(page)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return nil
        }
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
                let songsFolderRequest = try JSONDecoder().decode(FolderSongsResponse.self, from: data)
                completion(.success(songsFolderRequest))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }
    
    func fetchSongsWithName(with name: String,page : Int,completion: @escaping (Result<FolderSongsResponse, Error>) -> Void) -> URLSessionDataTask? {
        
        guard let url = URL(string: "\(baseURL)/filter_music?text=\(name)&page_number=\(page)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return nil
        }
        print("fetchSongsWithName \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔎 JSON String:\n\(jsonString)")
            }
            do {
                let songsFolderRequest = try JSONDecoder().decode(FolderSongsResponse.self, from: data)
                completion(.success(songsFolderRequest))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }
}
