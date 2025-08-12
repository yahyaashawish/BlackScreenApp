//
//  FontViewModel.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 30/06/2025.
//

import SwiftUI
import CoreData
@MainActor
class FontViewModel: ObservableObject {
    
    var localFonts: [LocalFont] = []
    @Published var downLoadedFonts: [LocalFont] = []
    var fetchedFontsCount: Int = 0
    @Published var selectedFontType: FontType = .en
    let coreDataHelper = CoreDataHelper.shared
    private var currentEnglishPage = 1
    private var currentArabicPage = 1
    @Published var isFetching = false
    private var hasMoreEnglishPages = true
    private var hasMoreArabicPages = true
    var currentTask : URLSessionDataTask? = nil
    var downloadsTasks: [URLSessionDownloadTask] = []
    
    

    func fetchFontsForNextPage(isNewType : Bool)  {
        if isNewType {
            localFonts.removeAll()
            downLoadedFonts.removeAll()
            loadLocalFonts()
        }
        switch selectedFontType {
        case .ar:
            guard !isFetching, hasMoreArabicPages else {

                return }

        case .en:
            guard !isFetching, hasMoreEnglishPages else {

                return }
        }
        
        isFetching = true

        currentTask = FontRequest.shared.fetchFontsData(page: selectedFontType == .ar ? currentArabicPage : currentEnglishPage,type: selectedFontType)  { result in
                switch result {
                case .success(let fontResponse):
                    
                    self.fetchedFontsCount = fontResponse.page.TotalPages
                    
                    if fontResponse.page.TotalRecords > self.localFonts.count {
                        for font in fontResponse.data {
                            let exists = self.localFonts.contains(where :{localFont in
                                localFont.id == Int64(font.id)
                            })
                            if !exists {
                                DispatchQueue.main.async {

                                let fileName = "\(font.font_name).ttf"
                                let localFont = LocalFont(context: self.coreDataHelper.persistentContainer.viewContext)
                                localFont.id = Int64(font.id)
                                localFont.name = font.name
                                localFont.fontName = font.font_name
                                localFont.fileName = fileName
                                localFont.fileURL = font.file
                                localFont.type = self.selectedFontType.rawValue
                                try? self.coreDataHelper.persistentContainer.viewContext.save()
                                    self.localFonts.append(localFont)
                                    self.downLoadAndRegisterLocalFont(localFont: localFont)
                                }
                            }
                        }

                        switch self.selectedFontType {
                        case .ar:
                            if self.currentArabicPage >= fontResponse.page.TotalPages {
                                self.hasMoreArabicPages = false
                            } else {
                                self.currentArabicPage += 1
                                
                            }
                        case .en:
                            if self.currentEnglishPage >= fontResponse.page.TotalPages {
                                self.hasMoreEnglishPages = false
                            } else {
                                self.currentEnglishPage += 1
                            }
                        }

                    }else{
                        switch self.selectedFontType {
                        case .ar:
                            self.currentArabicPage = fontResponse.page.TotalPages
                            self.hasMoreArabicPages = false
                        case .en:
                            self.currentEnglishPage = fontResponse.page.TotalPages
                            self.hasMoreEnglishPages = false

                        }
                    }
                    DispatchQueue.main.async {
                        self.isFetching = false
                    }
                   
                    

                    
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        self.isFetching = false
                    }
                }
            }
    }
    
    func changeFontType(_ fontType: FontType) {
        selectedFontType = fontType
        fetchFontsForNextPage(isNewType: true)
    }
    
    func loadLocalFonts() {
        
        let request: NSFetchRequest<LocalFont> = LocalFont.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LocalFont.name, ascending: true)]
        request.predicate = NSPredicate(format: "type == %@", selectedFontType.rawValue)
        do {
            localFonts = try coreDataHelper.persistentContainer.viewContext.fetch(request)
            downloadAllLocalFonts()
        } catch {
            localFonts = []
        }
    }
    func downloadAllLocalFonts() {
        self.downLoadedFonts.removeAll()
        self.isFetching = true
        for localFont in localFonts {
            downLoadAndRegisterLocalFont(localFont: localFont)
        }
        self.isFetching = false
    }
    func downLoadAndRegisterLocalFont(localFont : LocalFont){
        if let fileURL = localFont.fileURL , let fileName = localFont.fontName{
            if localFont.isDownloaded {
                self.downLoadedFonts.append(localFont)
                _ = FontManager.shared.registerFontIfNeeded(for: fileName)
                return
            }
            let downloadTask = FontManager.shared.downloadAndRegisterFont(from: fileURL, fontName: fileName) { success, url in
                if success {
                    
                    DispatchQueue.main.async {
                        self.makeLocalFontDownloaded(localFont : localFont)
                        self.downLoadedFonts.append(localFont)
                    }
                }else{
                    DispatchQueue.main.async {
                    }
                }
            }
            if let task = downloadTask {
                downloadsTasks.append(task)
            }
        }
                
                
                    
    }
    func makeLocalFontDownloaded(localFont : LocalFont){
        if let index = self.localFonts.firstIndex(where: { $0.id == localFont.id }){
            localFonts[index].isDownloaded = true
        }
        localFont.isDownloaded = true
        try? self.coreDataHelper.persistentContainer.viewContext.save()
    }
    func registerLocalFonts(){
        for localFont in self.localFonts {
            if let fontName = localFont.fontName{
                _ = FontManager.shared.registerFontIfNeeded(for: fontName)
            }
        }

    }
    
    deinit{
        for task in downloadsTasks {
            task.cancel()
        }
        currentTask?.cancel()
    }
}
