//
//  BlackScreenVideoApp.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 13/05/2025.
//

import SwiftUI

@main
struct BlackScreenVideoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State var languageSettings = LanguageSetting.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(languageSettings)
                .environment(\.locale, languageSettings.locale)
                .environment(\.layoutDirection,  languageSettings.isRightToLeft ? .rightToLeft : .leftToRight)
                .environment(\.managedObjectContext,
                              CoreDataHelper.shared.persistentContainer.viewContext)
                .environment(\.colorScheme, .dark)

                .onChange(of: scenePhase) { oldPhase,newPhase in
                    if newPhase == .active {
                        AppOpenAdManager.shared.showAdIfAvailable()
                    }
                    
                }
                .onAppear{
                    UserIdentifier.shared.setIdentifier()
                }
                
        }

    }
}
