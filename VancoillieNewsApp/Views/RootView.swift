//
//  RootView.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 10/10/2025.
//


import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(NSLocalizedString("tab.home", comment: ""), systemImage: "house") }

            ArticlesView()
                .tabItem { Label(NSLocalizedString("tab.articles", comment: ""), systemImage: "newspaper") }

            SettingsView()
                .tabItem { Label(NSLocalizedString("tab.settings", comment: ""), systemImage: "gearshape") }
        }
        .tint(Brand.blue)
    }
}