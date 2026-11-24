import SwiftUI
import CycleCore

struct SharerTodayView: View {
    @EnvironmentObject private var sharer: SharerStore
    @State private var showingOtherDay = false

    var body: some View {
        NavigationStack {
            List {
                if let estimate = sharer.estimate {
                    heroSection(estimate)
                    detailsSection(estimate)
                    if sharer.showsCheckInCard {
                        checkInSection
                    }
                    tidbitSection(estimate)
                } else {
                    emptySection
                }
                logSection
                historySection
            }
            .navigationTitle(Copy.Sharer.todayTitle)
            .sheet(isPresented: $showingOtherDay) {
                LogOtherDaySheet { date in
                    Task { await sharer.logPeriodStart(on: date) }
                }
            }
        }
    }

    // MARK: Sections

    private func heroSection(_ estimate: CycleEstimate) -> some View {
        let background = ColorScale.color(at: estimate.colorPosition)
        let foreground = Color(ColorScale.foreground(on: background))
        return Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(Copy.Day.ofCycle(estimate.cycleDay, length: estimate.cycleLength))
                    .font(.system(.title, design: .rounded).weight(.bold))
                Text(Copy.Phases.name(estimate.phase))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Text(Copy.Phases.line(estimate.phase))
                    .font(.subheadline)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .accessibilityElement(children: .combine)
            .listRowBackground(Color(background))
        }
    }

    private func detailsSection(_ estimate: CycleEstimate) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(Copy.ConfidenceText.label(estimate.confidence))
                    .font(.subheadline.weight(.semibold))
                Text(Copy.ConfidenceText.explanation(estimate.confidence))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 4) {
                Text(Copy.NextPeriod.title)
                    .font(.subheadline.weight(.semibold))
                if estimate.isRunningBehind {
                    Text(Copy.NextPeriod.runningBehind)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(Copy.NextPeriod.around(
                        estimate.nextStartWindow.lowerBound.formatted(.dateTime.day().month()),
                        estimate.nextStartWindow.upperBound.formatted(.dateTime.day().month())
                    ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var checkInSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text(Copy.CheckIn.title)
                    .font(.system(.headline, design: .rounded))
                Text(Copy.CheckIn.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Button(Copy.CheckIn.actionLog) {
                        Task { await sharer.logPeriodStart() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(ColorScale.color(at: 0.6)))
                    Button(Copy.CheckIn.cardDismiss) {
                        sharer.dismissCheckInCard()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(Color(ColorScale.color(at: 0.12)))
        }
    }

    private func tidbitSection(_ estimate: CycleEstimate) -> some View {
        Section(Copy.Sharer.tidbitTitle) {
            Text(Education.tidbit(for: estimate.phase, on: .now))
                .font(.subheadline)
        }
    }

    private var emptySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.Sharer.noDataTitle)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Text(Copy.Sharer.noDataBody)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            if !sharer.healthConnected && sharer.isHealthAvailable {
                Button(Copy.Settings.healthConnect) {
                    Task { await sharer.connectHealth() }
                }
            }
        }
    }

    private var logSection: some View {
        Section {
            Button(Copy.Sharer.logStart) {
                Task { await sharer.logPeriodStart() }
            }
            Button(Copy.Sharer.logStartOtherDay) {
                showingOtherDay = true
            }
        }
    }

    private var historySection: some View {
        Section(Copy.Sharer.historyTitle) {
            let starts = sharer.allStarts
            if starts.isEmpty {
                Text(Copy.Sharer.historyEmpty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(starts, id: \.self) { date in
                    let manual = sharer.isManual(date)
                    HStack {
                        Text(date.formatted(.dateTime.day().month().year()))
                        Spacer()
                        Text(manual ? Copy.Sharer.historyManual : Copy.Sharer.historyFromHealth)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if manual {
                            Button(role: .destructive) {
                                Task { await sharer.removeManualStart(date) }
                            } label: {
                                Label(Copy.Settings.deleteConfirmAction, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Pick a past day for a period start.
struct LogOtherDaySheet: View {
    let onConfirm: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(Copy.Sharer.logStartOtherDay, selection: $date, in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                Button {
                    onConfirm(date)
                    dismiss()
                } label: {
                    Text(Copy.CheckIn.actionLog)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(ColorScale.color(at: 0.6)))
                .controlSize(.large)
                Spacer()
            }
            .padding(16)
            .navigationTitle(Copy.Sharer.logStartOtherDay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.Sharing.cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}
