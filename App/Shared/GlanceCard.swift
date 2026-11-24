import SwiftUI
import CycleCore

/// The glance itself: drawn identically in the widget, on the Viewer's home screen,
/// and in the Sharer's "their view right now" preview. Text is always present;
/// colour is never the only thing carrying the meaning.
struct GlanceCard: View {
    let content: GlanceContent
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(content.title)
                    .font(.system(isCompact ? .title2 : .title, design: .rounded).weight(.bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if content.showsOvulationAccent {
                    Circle()
                        .fill(Color(ColorScale.ovulationAccent))
                        .frame(width: 9, height: 9)
                        .accessibilityHidden(true)
                }
            }
            if let subtitle = content.subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            if let message = content.message {
                Text(message)
                    .font(.system(isCompact ? .caption : .footnote, design: .rounded))
                    .lineLimit(isCompact ? 3 : 2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(Color(content.foreground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }
}
