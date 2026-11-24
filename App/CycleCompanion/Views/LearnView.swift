import SwiftUI
import CycleCore

/// Phase education, shared by both roles.
struct LearnView: View {
    var currentPhase: Phase?

    var body: some View {
        NavigationStack {
            List(Education.allGuides, id: \.phase) { guide in
                NavigationLink {
                    PhaseGuideView(guide: guide)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(guide.name)
                                .font(.system(.headline, design: .rounded))
                            Text(guide.typicalDays)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if guide.phase == currentPhase {
                            Circle()
                                .fill(Color(ColorScale.color(at: 0.55)))
                                .frame(width: 10, height: 10)
                                .accessibilityLabel(Copy.Phases.name(guide.phase))
                        }
                    }
                }
            }
            .navigationTitle(Copy.Viewer.learnTitle)
        }
    }
}

struct PhaseGuideView: View {
    let guide: PhaseGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(guide.headline)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(guide.typicalDays)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                section(title: Copy.Viewer.whatIsHappening) {
                    Text(guide.whatIsHappening).font(.body)
                }
                section(title: Copy.Viewer.mightFeelLike) {
                    Text(guide.mightFeelLike).font(.body)
                }
                section(title: Copy.Viewer.howToHelp) {
                    BulletList(items: guide.howToHelp)
                }

                Text(Education.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(guide.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded))
            content()
        }
        .softCard()
    }
}

/// A simple bulleted list using small dots rather than text glyphs.
struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(Color(ColorScale.color(at: 0.5)))
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
