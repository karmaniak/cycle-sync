import Foundation

/// Static, bundled education content written for the Viewer (the partner).
public struct PhaseGuide: Equatable, Sendable {
    public let phase: Phase
    public let name: String
    public let shortName: String
    public let typicalDays: String
    public let headline: String
    public let whatIsHappening: String
    public let mightFeelLike: String
    public let howToHelp: [String]

    public init(
        phase: Phase,
        name: String,
        shortName: String,
        typicalDays: String,
        headline: String,
        whatIsHappening: String,
        mightFeelLike: String,
        howToHelp: [String]
    ) {
        self.phase = phase
        self.name = name
        self.shortName = shortName
        self.typicalDays = typicalDays
        self.headline = headline
        self.whatIsHappening = whatIsHappening
        self.mightFeelLike = mightFeelLike
        self.howToHelp = howToHelp
    }
}

public enum Education {

    // MARK: - Guides

    public static func guide(for phase: Phase) -> PhaseGuide {
        switch phase {
        case .menstrual: return menstrualGuide
        case .follicular: return follicularGuide
        case .ovulation: return ovulationGuide
        case .luteal: return lutealGuide
        }
    }

    public static let allGuides: [PhaseGuide] = [
        menstrualGuide,
        follicularGuide,
        ovulationGuide,
        lutealGuide,
    ]

    private static let menstrualGuide = PhaseGuide(
        phase: .menstrual,
        name: "Menstrual phase",
        shortName: "Menstrual",
        typicalDays: "Roughly days 1 to 5",
        headline: "Rest, warmth, and a little extra kindness",
        whatIsHappening: "The uterine lining that built up over the last cycle is shed, and that is what a period is. Estrogen and progesterone are both at their lowest, and the body is quietly resetting for the next cycle. Bleeding often lasts a few days, though the length varies from person to person.",
        mightFeelLike: "Many people feel tired or crampy, and some want more rest and comfort. Others feel fine, or even light and relieved. Everyone is different, so asking how she feels today beats guessing.",
        howToHelp: [
            "Offer a warm drink, a heating pad, or a cozy blanket.",
            "Ask what would feel good today, then follow her lead.",
            "Take something off her plate, like dinner or an errand.",
            "Keep plans flexible and make staying in feel completely fine.",
        ]
    )

    private static let follicularGuide = PhaseGuide(
        phase: .follicular,
        name: "Follicular phase",
        shortName: "Follicular",
        typicalDays: "Roughly days 6 to 12",
        headline: "Energy is climbing",
        whatIsHappening: "After the period, the body gets going on the next cycle. Follicles in the ovary begin to grow, each holding an egg, and estrogen starts to rise. The uterine lining slowly rebuilds, ready for what comes next.",
        mightFeelLike: "Many people notice their energy and mood lifting gradually, and some feel more social or curious. Others notice no change at all, which is perfectly normal. Asking about her week is a nice way to find out.",
        howToHelp: [
            "Suggest something active or new, like a walk or a new cafe.",
            "Match her energy, and be ready for plans she suddenly feels like making.",
            "Ask what she is looking forward to this week.",
            "Cheer on the small wins, even the tiny ones.",
        ]
    )

    private static let ovulationGuide = PhaseGuide(
        phase: .ovulation,
        name: "Ovulation phase",
        shortName: "Ovulation",
        typicalDays: "Around days 13 to 15",
        headline: "A short, bright moment mid-cycle",
        whatIsHappening: "Rising estrogen leads to a surge of luteinizing hormone, or LH. That surge triggers ovulation, when an egg is released from an ovary. It is a brief moment in the middle of the cycle, and the timing varies from person to person.",
        mightFeelLike: "Some people feel confident, chatty, or full of energy around now. Some notice a small twinge on one side. Many notice nothing at all, and that is normal too.",
        howToHelp: [
            "Suggest something social or fun if she is in the mood.",
            "Kind words are always welcome, so be specific and sincere.",
            "Check in lightly rather than assuming how she feels.",
            "Keep things easygoing. Some days just feel nice.",
        ]
    )

    private static let lutealGuide = PhaseGuide(
        phase: .luteal,
        name: "Luteal phase",
        shortName: "Luteal",
        typicalDays: "Roughly days 16 to 28",
        headline: "Slowing down, nesting, and comfort",
        whatIsHappening: "After ovulation, progesterone becomes the main player and keeps the uterine lining ready. Toward the end of this phase, progesterone and estrogen both fall, which signals the lining to be shed and the next period to begin.",
        mightFeelLike: "Many people want quieter evenings and comfort food as this phase goes on. Some feel more sensitive, tired, or tender, and others feel steady and focused. Asking is always better than assuming.",
        howToHelp: [
            "Offer a calm night in, with a favorite show or meal.",
            "Be patient with the small stuff and generous with hugs.",
            "Ask what would help, and believe the answer.",
            "Stock up on her favorite snacks and comfort items.",
        ]
    )

    // MARK: - Tidbits

    public static func tidbits(for phase: Phase) -> [String] {
        switch phase {
        case .menstrual:
            return [
                "A period is the uterine lining leaving the body. It is a normal, healthy part of the cycle.",
                "Period length varies a lot. Anywhere from about three to seven days is common.",
                "Cramps happen when the uterus contracts to shed its lining. Warmth often helps.",
                "Estrogen and progesterone are at their lowest now, which is part of why energy can dip.",
                "Some people feel lighter and relieved when a period starts. Everyone is different.",
                "A heating pad, a snack, and a calm evening can be a surprisingly great gift.",
                "Day 1 of the cycle is the first day of bleeding. Everything else is counted from there.",
                "Ask \"what would help today?\" instead of guessing. The answer changes from cycle to cycle.",
                "Many people find rest, gentle movement, and good food make these days easier.",
                "A period is the body doing its regular work. Nothing to whisper about.",
                "Not every month feels the same. Today's answer is the one that counts.",
            ]
        case .follicular:
            return [
                "Follicles are tiny sacs in the ovary that each hold an egg. Several start to grow now.",
                "Estrogen rises through this phase, and many people notice their energy rising with it.",
                "The uterine lining is rebuilding after the period. The body is quietly renovating.",
                "Many people feel more motivated or social in this phase. Some do not, and that is fine.",
                "Technically this phase starts with the period and runs until ovulation.",
                "Often one follicle takes the lead and keeps maturing while the others fade away.",
                "A good time to suggest something new. Plenty of people feel curious and ready to try things.",
                "This phase varies the most in length, from person to person and cycle to cycle.",
                "Rising estrogen can affect sleep, skin, and mood in different ways for different people.",
                "A little encouragement goes far. Ask your partner what she is excited about this week.",
                "Energy often builds gradually, so a slow start to this phase is perfectly normal.",
            ]
        case .ovulation:
            return [
                "Ovulation is when an egg is released from an ovary. It is a brief moment in the cycle.",
                "A rise in luteinizing hormone, or LH, is the signal that triggers the egg's release.",
                "Estrogen usually peaks just before ovulation, and many people feel energetic around then.",
                "Some people feel a small twinge on one side around ovulation. Many feel nothing at all.",
                "Ovulation usually happens around the middle of the cycle, but timing varies widely.",
                "After release, the egg travels along a fallopian tube. A small, quiet journey.",
                "Some people notice changes in how they feel in their body mid-cycle. Others do not.",
                "Feeling confident or chatty mid-cycle is common, but never guaranteed.",
                "This phase is short. It is more of a moment than a stretch of days.",
                "Cycles differ, so the middle of the cycle lands on a different day for everyone.",
                "A genuine compliment is always welcome, whatever the phase.",
            ]
        case .luteal:
            return [
                "The luteal phase begins after ovulation. Progesterone is the star of the show now.",
                "After the egg is released, the follicle becomes the corpus luteum, which makes progesterone.",
                "Progesterone can make some people feel warmer, sleepier, or more in need of rest.",
                "Toward the end of this phase, estrogen and progesterone both fall and the next period begins.",
                "Many people crave comfort food and cozy evenings in this phase. Honor the snack.",
                "Some people feel tender or sensitive near the end of the cycle. Others feel steady as ever.",
                "This phase is often around two weeks long, though it varies from person to person.",
                "A quiet night in can be the best plan right now. Ask what sounds good.",
                "Body temperature tends to rise slightly after ovulation because of progesterone.",
                "Small kindnesses add up, like doing the dishes without being asked.",
                "Sleep and appetite can shift in this phase. Patience and snacks help.",
            ]
        }
    }

    public static func tidbit(for phase: Phase, on date: Date, calendar: Calendar = .current) -> String {
        pick(from: tidbits(for: phase), on: date, calendar: calendar)
    }

    // MARK: - Widget lines

    public static func widgetLines(for phase: Phase) -> [String] {
        switch phase {
        case .menstrual:
            return [
                "A good day for tea and patience.",
                "Warm blankets are a great idea.",
                "Rest is productive today.",
                "Soft pace, soft snacks.",
                "Extra kindness goes a long way.",
                "Heating pad weather, maybe.",
                "Ask what would feel good.",
            ]
        case .follicular:
            return [
                "Energy is climbing.",
                "A good day to try something new.",
                "A fresh-start kind of feeling.",
                "Let's make a plan together.",
                "Lots of possibility in the air.",
                "Ask what she's excited about.",
                "Cheer on the small wins.",
            ]
        case .ovulation:
            return [
                "A bright, chatty kind of day?",
                "A fine day for a little outing.",
                "Say something kind today.",
                "Social plans might sound fun.",
                "Mid-cycle sparkle, maybe.",
                "Good day for a walk together.",
                "Easygoing is the way to go.",
            ]
        case .luteal:
            return [
                "Cozy mode is a fine mode.",
                "Snacks and soft socks, anyone?",
                "A good night for a slow dinner.",
                "Patience and a good playlist.",
                "Ask what would feel comforting.",
                "Slow evenings are welcome.",
                "Gentle plans are good plans.",
            ]
        }
    }

    public static func widgetLine(for phase: Phase, on date: Date, calendar: Calendar = .current) -> String {
        pick(from: widgetLines(for: phase), on: date, calendar: calendar)
    }

    // MARK: - Disclaimer

    public static let disclaimer: String =
        "General information only, not medical advice. Every body and every cycle is different."

    // MARK: - Helpers

    private static func pick(from items: [String], on date: Date, calendar: Calendar) -> String {
        guard !items.isEmpty else { return "" }
        let ordinal = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let count = items.count
        let index = ((ordinal % count) + count) % count
        return items[index]
    }
}
