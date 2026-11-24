import WidgetKit
import SwiftUI
import CycleCore

struct GlanceEntry: TimelineEntry {
    let date: Date
    let content: GlanceContent
}

struct GlanceProvider: TimelineProvider {
    private let store = SnapshotStore.shared

    func placeholder(in context: Context) -> GlanceEntry {
        GlanceEntry(date: .now, content: Glance.content(snapshot: Self.sample, on: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
        let snapshot = context.isPreview ? (store.load() ?? Self.sample) : store.load()
        completion(GlanceEntry(date: .now, content: Glance.content(snapshot: snapshot, on: .now, options: store.options)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
        Task {
            var snapshot = store.load()
            // A Viewer's widget checks iCloud itself, so it stays fresh (and notices a
            // pause or a revoke) even if the app has not been opened.
            if store.role == .viewer {
                do {
                    snapshot = try await CloudSharingService().fetchShared()
                    store.save(snapshot, reload: false)
                } catch {
                    // Offline or iCloud busy: keep what we have.
                }
            }
            let calendar = Calendar.current
            let options = store.options
            let today = calendar.startOfDay(for: .now)
            // One entry per day: the shared forecast covers a week, then it reads "catching up".
            let entries: [GlanceEntry] = (0...SharedSnapshot.horizonDays).map { offset in
                let day = calendar.date(byAdding: .day, value: offset, to: today)!
                return GlanceEntry(
                    date: offset == 0 ? .now : day,
                    content: Glance.content(snapshot: snapshot, on: day, calendar: calendar, options: options)
                )
            }
            let nextCheck = calendar.date(byAdding: .hour, value: 6, to: .now)!
            completion(Timeline(entries: entries, policy: .after(nextCheck)))
        }
    }

    static var sample: SharedSnapshot {
        let key = SharedSnapshot.dayKey(.now)
        return SharedSnapshot(status: .active, detail: .dayAndPhase, updatedAt: .now, days: [
            .init(date: key, cycleDay: 2, phase: .menstrual, confidence: .high, color: 0.92),
        ])
    }
}

struct CycleWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GlanceEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.content.inlineText)
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    if let day = entry.content.cycleDay {
                        Text("\(day)").font(.title2.weight(.semibold))
                    }
                    Text(circularLabel).font(.caption2).minimumScaleFactor(0.6).lineLimit(1)
                }
                .padding(4)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.content.accessibilityLabel)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.content.title).font(.headline)
                if let subtitle = entry.content.subtitle {
                    Text(subtitle).font(.subheadline)
                }
                if let message = entry.content.message {
                    Text(message).font(.caption).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.content.accessibilityLabel)
        default:
            GlanceCard(content: entry.content, isCompact: family == .systemSmall)
        }
    }

    private var circularLabel: String {
        if let phase = entry.content.phase { return String(Copy.Phases.name(phase).prefix(4)) }
        return entry.content.subtitle ?? entry.content.title
    }
}

@main
struct CycleCompanionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppIdentifiers.widgetKind, provider: GlanceProvider()) { entry in
            CycleWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(entry.content.background) }
        }
        .configurationDisplayName(Copy.Widget.displayName)
        .description(Copy.Widget.description)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
