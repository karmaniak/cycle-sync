import SwiftUI
import CycleCore

/// Chooses between onboarding and the two role-specific experiences.
struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var sharer: SharerStore
    @EnvironmentObject private var viewer: ViewerStore

    var body: some View {
        Group {
            switch model.role {
            case nil:
                OnboardingView()
            case .some(.sharer):
                SharerTabView()
            case .some(.viewer):
                ViewerTabView()
            }
        }
        .alert(Copy.appName, isPresented: errorBinding) {
            // The system supplies a plain dismiss button.
        } message: {
            Text(currentError ?? "")
        }
    }

    private var currentError: String? {
        switch model.role {
        case .some(.viewer): return viewer.errorMessage
        default: return sharer.errorMessage
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { currentError != nil },
            set: { shown in
                if !shown {
                    sharer.errorMessage = nil
                    viewer.errorMessage = nil
                }
            }
        )
    }
}

// MARK: - Small shared styling helpers

extension View {
    /// A soft rounded card used across screens.
    func softCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

/// The glance drawn on its own coloured, softly bordered tile.
struct GlanceTile: View {
    let content: GlanceContent
    var height: CGFloat = 170
    var fixedWidth: CGFloat? = nil

    var body: some View {
        GlanceCard(content: content)
            .padding(16)
            .frame(width: fixedWidth, height: height)
            .frame(maxWidth: fixedWidth == nil ? CGFloat.infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(content.background))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}
