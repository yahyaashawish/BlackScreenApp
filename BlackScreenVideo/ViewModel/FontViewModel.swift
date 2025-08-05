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
    
    @Published var localFonts: [LocalFont] = []
    let coreDataHelper = CoreDataHelper.shared
    private var currentPage = 1
    @Published var isFetching = false
    private var hasMorePages = true

    

    func fetchFontsForNextPage()  {
        loadLocalFonts()
        
        print("fetched core data local fonts for page \(localFonts.count)")

            
            guard !isFetching, hasMorePages else { return }
            isFetching = true
           

        FontRequest.shared.fetchFontsData(page: currentPage)  { result in
                switch result {
                case .success(let fontResponse):
                    print("fetched fonts count \(fontResponse.data.count)")
                    for font in fontResponse.data {
                        let exists = self.localFonts.contains(where :{localFont in
                             localFont.id == Int64(font.id)

                        })
                        if !exists {

                            FontManager.shared.downloadAndRegisterFont(from: font.file, fontName: font.font_name) { success, url in
                                if success {
                                    let fileName = "\(font.font_name).ttf"
                                    let localFont = LocalFont(context: self.coreDataHelper.persistentContainer.viewContext)
                                    localFont.id = Int64(font.id)
                                    localFont.name = font.name
                                    localFont.fontName = font.font_name
                                    localFont.fileName = fileName
                                    self.coreDataHelper.saveContext()
                                    DispatchQueue.main.async {
                                        self.localFonts.append(localFont)
                                    }
                                    
                                }else{
                                    print("faild while downloading font")
                                }
                            }
                            
                        }
                    }
                    DispatchQueue.main.async {
                        self.isFetching = false
                    }
                    if self.currentPage >= fontResponse.page.TotalPages {
                        self.hasMorePages = false
                    } else {
                        self.currentPage += 1
                    }

                    
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        self.isFetching = false
                    }
                }
            }
            registerLocalFonts()
       
        
        
        
       

    }
    
    func loadLocalFonts() {
        let request: NSFetchRequest<LocalFont> = LocalFont.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LocalFont.name, ascending: true)]
        
        do {
            localFonts = try coreDataHelper.persistentContainer.viewContext.fetch(request)
            print("local fonts count: \(localFonts.count)")
        } catch {
            print("Failed to fetch fonts from Core Data: \(error)")
            localFonts = []
        }
    }
    
    func registerLocalFonts(){
        for localFont in self.localFonts {
            if let fontName = localFont.fontName{
                _ = FontManager.shared.registerFontIfNeeded(for: fontName)
            }
        }

    }
}
