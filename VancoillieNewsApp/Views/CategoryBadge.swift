//
//  CategoryBadge.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 11/10/2025.
//


import SwiftUI

struct CategoryBadge: View {
    let name: String

    private var isBrand: Bool {
        name == "Vancoillie IT Hulp"
    }

    var body: some View {
        Group {
            if isBrand {
                Text(NSLocalizedString("badge.vancoillie", comment: ""))
                    .font(.caption2).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                    Text(name)
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                .foregroundStyle(.secondary)
            }
        }
    }
}