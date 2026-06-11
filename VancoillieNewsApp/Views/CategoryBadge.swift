import SwiftUI

struct CategoryBadge: View {
    let name: String

    private var color: Color { Brand.categoryColor(for: name) }
    private var displayName: String {
        name == "Vancoillie IT Hulp" ? NSLocalizedString("badge.vancoillie", comment: "") : name
    }

    var body: some View {
        Text(displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
