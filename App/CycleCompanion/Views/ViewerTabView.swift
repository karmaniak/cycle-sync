import SwiftUI
import CycleCore

struct ViewerTabView: View {
    @EnvironmentObject private var viewer: ViewerStore

    var body: some View {
        TabView {
            ViewerHomeView()
                .tabItem { Label(Copy.Tabs.today, systemImage: "sun.max") }
            LearnView(currentPhase: viewer.content.phase)
                .tabItem { Label(Copy.Tabs.learn, systemImage: "book") }
            ViewerSettingsView()
                .tabItem { Label(Copy.Tabs.settings, systemImage: "gearshape") }
        }
        .tint(Color(ColorScale.color(at: 0.6)))
    }
}

struct ViewerHomeView: View {
    @EnvironmentObject private var viewer: ViewerStore

    var body: some View {
        let content = viewer.content
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlanceTile(content: content, height: 220)

                    stateSection(content)

                    if viewer.isLinked, let updated = viewer.snapshot?.updatedAt {
                        Text(Copy.Viewer.updated(updated.formatted(.relative(presentation: .named))))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(Copy.Viewer.addWidgetTitle)
                            .font(.system(.headline, design: .rounded))
                        Text(Copy.Viewer.addWidgetBody)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .softCard()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Copy.Tabs.today)
            .refreshable { await viewer.refresh() }
        }
    }

    @ViewBuilder
    private func stateSection(_ content: GlanceContent) -> some View {
        switch content.kind {
        case .notLinked:
            infoCard(title: Copy.Viewer.notLinkedTitle, body: Copy.Viewer.notLinkedBody)
        case .paused:
            infoCard(title: Copy.Viewer.pausedTitle, body: Copy.Viewer.pausedBody)
        case .stale:
            infoCard(title: Copy.Viewer.staleTitle, body: Copy.Viewer.staleBody)
        case .uncertain:
            Text(Copy.ConfidenceText.phaseUncertainDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .softCard()
        case .live:
            if let phase = content.phase {
                let guide = Education.guide(for: phase)
                VStack(alignment: .leading, spacing: 10) {
                    Text(Copy.Viewer.aboutPhase)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(guide.headline)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                    Text(Copy.Viewer.whatIsHappening)
                        .font(.subheadline.weight(.semibold))
                    Text(guide.whatIsHappening)
                        .font(.subheadline)
                    Text(Copy.Viewer.howToHelp)
                        .font(.subheadline.weight(.semibold))
                    BulletList(items: guide.howToHelp)
                }
                .softCard()

                VStack(alignment: .leading, spacing: 6) {
                    Text(Copy.Sharer.tidbitTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Education.tidbit(for: phase, on: .now))
                        .font(.subheadline)
                }
                .softCard()
            }
            if let confidence = content.confidence {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Copy.ConfidenceText.label(confidence))
                        .font(.subheadline.weight(.semibold))
                    Text(Copy.ConfidenceText.explanation(confidence))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .softCard()
            }
        }
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.headline, design: .rounded))
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .softCard()
    }
}

struct ViewerSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var viewer: ViewerStore
    @State private var confirmUnlink = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(Copy.Settings.highContrast, isOn: $viewer.displayOptions.highContrast)
                    Toggle(Copy.Settings.showTidbit, isOn: $viewer.displayOptions.showsMessage)
                } footer: {
                    Text(Copy.Settings.highContrastFooter)
                }

                if viewer.isLinked {
                    Section {
                        Button(Copy.Viewer.unlink, role: .destructive) {
                            confirmUnlink = true
                        }
                    }
                }

                Section {
                    Button(Copy.Settings.switchRole) {
                        model.role = nil
                    }
                } footer: {
                    Text(Copy.Settings.about)
                }
            }
            .navigationTitle(Copy.Settings.title)
            .confirmationDialog(Copy.Viewer.unlinkConfirm, isPresented: $confirmUnlink, titleVisibility: .visible) {
                Button(Copy.Viewer.unlink, role: .destructive) {
                    Task { await viewer.unlink() }
                }
                Button(Copy.Sharing.cancel, role: .cancel) {}
            }
        }
    }
}
