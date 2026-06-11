import SwiftUI

struct OnboardingView: View {
    var isEditing: Bool = false

    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @AppStorage("pref.lang") private var language: String = "nl"
    @AppStorage("pref.categories") private var savedCategories: String = ""
    @Environment(\.dismiss) private var dismiss

    @State private var categories: [Category] = []
    @State private var selectedIDs: Set<Int> = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Brand.blue)
                    .padding(.top, 60)

                Text("Vancoillie News")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(isEditing
                     ? "Pas je categorieën aan.\nWijzigingen worden meteen toegepast."
                     : "Kies de categorieën die je wilt volgen.\nJe kan dit altijd aanpassen in de instellingen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer().frame(height: 36)

            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxHeight: .infinity)
            } else if categories.isEmpty {
                Text("Kon categorieën niet laden.")
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(categories) { cat in
                            CategoryToggleChip(
                                category: cat,
                                isSelected: selectedIDs.contains(cat.id)
                            ) {
                                if selectedIDs.contains(cat.id) {
                                    selectedIDs.remove(cat.id)
                                } else {
                                    selectedIDs.insert(cat.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    finish(keepSelection: true)
                } label: {
                    Text(isEditing ? "Opslaan" : (selectedIDs.isEmpty ? "Alles bekijken" : "Aan de slag"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Brand.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.white)
                }

                if !isEditing && !selectedIDs.isEmpty {
                    Button("Alles bekijken") {
                        finish(keepSelection: false)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                if isEditing {
                    Button("Annuleren") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .task { await loadCategories() }
    }

    private func loadCategories() async {
        isLoading = true
        if let cats = try? await APIClient.shared.fetchCategories(locale: language, forceRefresh: true) {
            categories = cats
            if isEditing {
                selectedIDs = Set(savedCategories.split(separator: ",").compactMap { Int($0) })
            }
        }
        isLoading = false
    }

    private func finish(keepSelection: Bool) {
        savedCategories = keepSelection
            ? selectedIDs.map { String($0) }.joined(separator: ",")
            : ""
        if isEditing {
            dismiss()
        } else {
            onboardingCompleted = true
        }
    }
}

private struct CategoryToggleChip: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void

    private var color: Color { Brand.categoryColor(for: category.name) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? color : Color.clear)
                    .overlay(Circle().strokeBorder(color.opacity(0.6), lineWidth: isSelected ? 0 : 1.5))
                    .frame(width: 10, height: 10)

                Text(category.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                isSelected ? color.opacity(0.12) : Color(UIColor.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1.5)
            }
            .foregroundStyle(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
