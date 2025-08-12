//
//  FontViewModel.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//

import SwiftUI
import CoreData
@MainActor
class SettingsVM: ObservableObject {
    
    @Published var showApplibrary : Bool = false
    @Published var isFetching : Bool = false

    var currentTask : URLSessionDataTask? = nil
    
    init(){
        fetchSettings()
    }
    func fetchSettings()  {
        isFetching = true
        currentTask = SettingsRequest.shared.fetchSettings { result in
            switch result {
            case .success(let settingResponse):
                DispatchQueue.main.async {
                    self.showApplibrary = settingResponse.data.show_music
                    self.isFetching = false
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self.isFetching = false
                }
            }
        }
    }
    
    
    deinit {
        currentTask?.cancel()
    }
}
