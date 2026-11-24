import SwiftUI
import CycleCore

struct SharerSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var sharer: SharerStore
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                cycleSection
                checkInSection
                healthSection
                displaySection
                privacySection
                Section {
                    Button(Copy.Settings.switchRole) {
                        model.role = nil
                    }
                } footer: {
                    Text(Copy.Settings.about)
                }
            }
            .navigationTitle(Copy.Settings.title)
            .confirmationDialog(Copy.Settings.deleteConfirmTitle, isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(Copy.Settings.deleteConfirmAction, role: .destructive) {
                    Task { await sharer.deleteEverything() }
                }
                Button(Copy.Sharing.cancel, role: .cancel) {}
            } message: {
                Text(Copy.Settings.deleteConfirmBody)
            }
        }
    }

    // MARK: Bindings

    private var lengthBinding: Binding<Int?> {
        Binding(
            get: { sharer.typicalCycleLength },
            set: { value in Task { await sharer.setTypicalCycleLength(value) } }
        )
    }

    private var periodBinding: Binding<Int> {
        Binding(
            get: { sharer.periodLength },
            set: { value in Task { await sharer.setPeriodLength(value) } }
        )
    }

    private var toneBinding: Binding<CheckInTone> {
        Binding(
            get: { sharer.tone },
            set: { value in Task { await sharer.setTone(value) } }
        )
    }

    // MARK: Sections

    private var cycleSection: some View {
        Section(Copy.Settings.cycleSection) {
            Picker(Copy.Onboarding.typicalLengthTitle, selection: lengthBinding) {
                Text(Copy.Onboarding.typicalLengthAuto).tag(Int?.none)
                ForEach(21...40, id: \.self) { days in
                    Text(Copy.Onboarding.typicalLengthDays(days)).tag(Int?.some(days))
                }
            }
            Stepper(value: periodBinding, in: 2...10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Copy.Settings.periodLength)
                    Text(Copy.Onboarding.typicalLengthDays(sharer.periodLength))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var checkInSection: some View {
        Section {
            Picker(Copy.CheckIn.settingsTitle, selection: toneBinding) {
                ForEach(CheckInTone.allCases, id: \.self) { tone in
                    Text(Copy.CheckIn.toneName(tone)).tag(tone)
                }
            }
            Text(Copy.CheckIn.toneExplanation(sharer.tone))
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text(Copy.CheckIn.settingsTitle)
        } footer: {
            Text(Copy.CheckIn.settingsFooter)
        }
    }

    private var healthSection: some View {
        Section(Copy.Settings.healthSection) {
            if sharer.healthConnected {
                Label(Copy.Settings.healthConnected, systemImage: "checkmark.circle")
            } else if sharer.isHealthAvailable {
                Button(Copy.Settings.healthConnect) {
                    Task { await sharer.connectHealth() }
                }
            }
        }
    }

    private var displaySection: some View {
        Section {
            Toggle(Copy.Settings.highContrast, isOn: $sharer.displayOptions.highContrast)
            Toggle(Copy.Settings.showTidbit, isOn: $sharer.displayOptions.showsMessage)
        } footer: {
            Text(Copy.Settings.highContrastFooter)
        }
    }

    private var privacySection: some View {
        Section {
            Text(Copy.Settings.privacyBody)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(Copy.Settings.deleteEverything, role: .destructive) {
                confirmDelete = true
            }
        } header: {
            Text(Copy.Settings.privacySection)
        }
    }
}
