//
//  VancoillieNewsAppApp.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 10/10/2025.
//

import SwiftUI

@main
struct VancoillieNewsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("app.theme") private var themeRaw: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
        }
    }
}
