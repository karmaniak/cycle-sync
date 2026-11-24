import Foundation

/// A plain sRGB colour so the palette can live (and be tested) outside SwiftUI.
public struct RGB: Equatable, Codable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// WCAG relative luminance.
    public var luminance: Double {
        func channel(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    /// WCAG contrast ratio, 1...21.
    public func contrast(with other: RGB) -> Double {
        let (hi, lo) = (max(luminance, other.luminance), min(luminance, other.luminance))
        return (hi + 0.05) / (lo + 0.05)
    }

    func mixed(with other: RGB, amount: Double) -> RGB {
        RGB(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount
        )
    }
}

/// The white → soft pink → deep red scale.
///
/// Colour encodes *where in the cycle*, never urgency: it is palest just after a
/// period ends, warms through the cycle, and is deepest on the first days of the
/// period. It does not keep deepening when a period arrives later than expected.
public enum ColorScale {
    public static let stops: [RGB] = [
        RGB(hex: 0xFFFFFF), // just after a period
        RGB(hex: 0xFFEEF1),
        RGB(hex: 0xFFD3DC),
        RGB(hex: 0xF9A3B7),
        RGB(hex: 0xE65C82),
        RGB(hex: 0xBE1E4A),
        RGB(hex: 0x8E0E2E), // first day of the period
    ]

    /// Neutral background for not linked, paused and stale states.
    public static let neutral = RGB(hex: 0xF4F1EE)
    public static let ink = RGB(hex: 0x3A1A22)
    public static let paper = RGB(hex: 0xFFFFFF)
    /// A small warm accent used to mark ovulation, since it has no place on a one-way scale.
    public static let ovulationAccent = RGB(hex: 0xE8A33D)

    /// Position on the scale, 0 (white) to 1 (deep red).
    public static func position(cycleDay: Int, cycleLength: Int, periodLength: Int) -> Double {
        let day = max(cycleDay, 1)
        if day <= periodLength {
            // Deepest on day one, easing through the period.
            let t = periodLength > 1 ? Double(day - 1) / Double(periodLength - 1) : 0
            return 1.0 - 0.3 * t
        }
        let span = Double(max(cycleLength - periodLength, 1))
        let t = min(Double(day - periodLength - 1), span - 1) / span
        return pow(max(t, 0), 1.6)
    }

    public static func color(at position: Double) -> RGB {
        let p = min(max(position, 0), 1) * Double(stops.count - 1)
        let lower = min(Int(p), stops.count - 2)
        return stops[lower].mixed(with: stops[lower + 1], amount: p - Double(lower))
    }

    /// Dark ink or white, whichever reads better on the given background.
    public static func foreground(on background: RGB) -> RGB {
        // Mid-rose shades sit where neither ink nor white reaches 4.5:1, so pure black steps in there.
        let best = [ink, paper].max { background.contrast(with: $0) < background.contrast(with: $1) }!
        return background.contrast(with: best) >= 4.5 ? best : RGB(hex: 0x000000)
    }

    /// A plain word for a shade, so colour is never the only carrier of meaning.
    public static func shadeName(at position: Double) -> String {
        switch position {
        case ..<0.08: return Copy.Shade.white
        case ..<0.3: return Copy.Shade.blush
        case ..<0.55: return Copy.Shade.softPink
        case ..<0.75: return Copy.Shade.rose
        case ..<0.9: return Copy.Shade.red
        default: return Copy.Shade.deepRed
        }
    }
}
