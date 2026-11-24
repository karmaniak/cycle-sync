import SwiftUI
import CloudKit
import CycleCore

/// Wraps what the system invite sheet needs so it can drive `.sheet(item:)`.
struct ShareSheetItem: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}

struct SharingView: View {
    @EnvironmentObject private var sharer: SharerStore
    @State private var sheetItem: ShareSheetItem?
    @State private var confirmStop = false

    var body: some View {
        NavigationStack {
            Form {
                if !sharer.isSharing {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(Copy.Sharing.notSharingTitle)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                            Text(Copy.Sharing.notSharingBody)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                detailSection
                previewSection

                if sharer.isSharing {
                    Section {
                        Toggle(Copy.Sharing.pauseTitle, isOn: pausedBinding)
                    } footer: {
                        Text(Copy.Sharing.pauseBody)
                    }
                    Section {
                        Button(Copy.Sharing.manage) { presentSheet() }
                        Button(Copy.Sharing.stop, role: .destructive) { confirmStop = true }
                    }
                } else {
                    Section {
                        Button(Copy.Sharing.invite) { presentSheet() }
                            .disabled(!sharer.iCloudAvailable)
                    } footer: {
                        if !sharer.iCloudAvailable {
                            Text(Copy.Sharing.iCloudUnavailable)
                        }
                    }
                }

                Section {
                    Text(Copy.Sharing.whatIsNeverShared)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Copy.Sharing.title)
            .sheet(item: $sheetItem) { item in
                CloudSharingSheet(share: item.share, container: item.container) {
                    Task { await sharer.sharingSheetDidClose() }
                }
            }
            .confirmationDialog(Copy.Sharing.stopConfirmTitle, isPresented: $confirmStop, titleVisibility: .visible) {
                Button(Copy.Sharing.stopConfirmAction, role: .destructive) {
                    Task { await sharer.stopSharing() }
                }
                Button(Copy.Sharing.cancel, role: .cancel) {}
            } message: {
                Text(Copy.Sharing.stopConfirmBody)
            }
        }
    }

    // MARK: Pieces

    private var detailBinding: Binding<ShareDetail> {
        Binding(
            get: { sharer.detail },
            set: { value in Task { await sharer.setDetail(value) } }
        )
    }

    private var pausedBinding: Binding<Bool> {
        Binding(
            get: { sharer.isPaused },
            set: { value in Task { await sharer.setPaused(value) } }
        )
    }

    private var detailSection: some View {
        Section {
            Picker(Copy.Sharing.detailTitle, selection: detailBinding) {
                ForEach(ShareDetail.allCases, id: \.self) { detail in
                    Text(Copy.Sharing.detailName(detail)).tag(detail)
                }
            }
            .pickerStyle(.menu)
            Text(Copy.Sharing.detailExplanation(sharer.detail))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var previewSection: some View {
        let content = Glance.content(snapshot: sharer.previewSnapshot, on: .now, options: sharer.displayOptions)
        return Section(Copy.Sharing.previewTitle) {
            HStack {
                Spacer()
                GlanceTile(content: content, height: 170, fixedWidth: 170)
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    private func presentSheet() {
        Task {
            if let result = await sharer.prepareShare() {
                sheetItem = ShareSheetItem(share: result.0, container: result.1)
            }
        }
    }
}
