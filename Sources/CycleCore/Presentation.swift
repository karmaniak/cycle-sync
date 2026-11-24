import Foundation

/// Everything a widget or the Viewer's home screen needs to draw, already decided.
/// Views stay dumb; the rules live here where they can be tested.
public struct GlanceContent: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case notLinked, paused, stale, uncertain, live
    }

    public let kind: Kind
    /// Big text: "Day 2", a phase name, or a state title.
    public let title: String
    /// Smaller label under the title: the phase name, "Phase estimate", or nil.
    public let subtitle: String?
    /// One friendly line.
    public let message: String?
    public let phase: Phase?
    public let cycleDay: Int?
    public let confidence: Confidence?
    public let background: RGB
    public let foreground: RGB
    /// True when the view should draw the small ovulation accent.
    public let showsOvulationAccent: Bool
    /// Text that fully describes the state for VoiceOver.
    public let accessibilityLabel: String
    /// Shortest useful text, for the inline Lock Screen widget.
    public let inlineText: String
}

public enum Glance {
    public struct Options: Equatable, Sendable {
        /// Black-on-white (or the reverse), with everything written out.
        public var highContrast: Bool
        /// Show the friendly one-liner.
        public var showsMessage: Bool

        public init(highContrast: Bool = false, showsMessage: Bool = true) {
            self.highContrast = highContrast
            self.showsMessage = showsMessage
        }
    }

    public static func content(
        snapshot: SharedSnapshot?,
        on date: Date,
        calendar: Calendar = .current,
        options: Options = Options()
    ) -> GlanceContent {
        guard let snapshot else {
            return neutral(.notLinked, Copy.Widget.notLinkedTitle, Copy.Widget.notLinkedMessage, inline: Copy.Widget.inlineNotLinked)
        }
        guard snapshot.status == .active else {
            return neutral(.paused, Copy.Widget.pausedTitle, Copy.Widget.pausedMessage, inline: Copy.Widget.inlinePaused)
        }
        guard let day = snapshot.day(for: date, calendar: calendar) else {
            return neutral(.stale, Copy.Widget.staleTitle, Copy.Widget.staleMessage, inline: Copy.Widget.inlineStale)
        }
        guard let position = day.color else {
            return neutral(.uncertain, Copy.ConfidenceText.phaseUncertain, Copy.ConfidenceText.phaseUncertainDetail, inline: Copy.ConfidenceText.phaseUncertain)
        }

        let background = options.highContrast ? ColorScale.paper : ColorScale.color(at: position)
        let foreground = options.highContrast ? RGB(hex: 0x000000) : ColorScale.foreground(on: background)
        let shade = ColorScale.shadeName(at: position)
        let isEstimate = day.confidence == .low

        let title: String
        var subtitle: String?
        var message: String?
        if let phase = day.phase {
            let phaseName = Copy.Phases.name(phase)
            if let cycleDay = day.cycleDay {
                title = Copy.Day.title(cycleDay)
                subtitle = phaseName
            } else {
                title = phaseName
            }
            if isEstimate {
                subtitle = subtitle.map { "\($0) · \(Copy.ConfidenceText.phaseEstimate)" } ?? Copy.ConfidenceText.phaseEstimate
            }
            if options.showsMessage {
                message = Education.widgetLine(for: phase, on: date, calendar: calendar)
            }
        } else {
            // Colour only: the shade is written out so colour is never the sole carrier.
            title = Copy.Widget.colorOnlyTitle
            subtitle = shade
        }

        let spoken = [title, subtitle, message].compactMap { $0 }.joined(separator: ". ")
        let inline = [day.cycleDay.map(Copy.Day.title), day.phase.map(Copy.Phases.name) ?? shade]
            .compactMap { $0 }.joined(separator: " · ")

        return GlanceContent(
            kind: .live,
            title: title,
            subtitle: subtitle,
            message: message,
            phase: day.phase,
            cycleDay: day.cycleDay,
            confidence: day.confidence,
            background: background,
            foreground: foreground,
            showsOvulationAccent: day.phase == .ovulation,
            accessibilityLabel: day.phase == nil ? Copy.Shade.accessibility(shade) : spoken,
            inlineText: inline
        )
    }

    private static func neutral(_ kind: GlanceContent.Kind, _ title: String, _ message: String, inline: String) -> GlanceContent {
        GlanceContent(
            kind: kind,
            title: title,
            subtitle: nil,
            message: message,
            phase: nil,
            cycleDay: nil,
            confidence: nil,
            background: ColorScale.neutral,
            foreground: ColorScale.ink,
            showsOvulationAccent: false,
            accessibilityLabel: "\(title). \(message)",
            inlineText: inline
        )
    }
}
