import Foundation

/// Every user-facing string in the app, widget and notifications lives here
/// (phase education lives beside it in Education.swift).
///
/// Voice: warm, plain, a little playful. Never clinical, never alarming.
/// Words we do not use anywhere: overdue, late, missed, warning.
public enum Copy {
    public static let appName = "Cycle Companion"

    public enum Phases {
        public static func name(_ phase: Phase) -> String {
            switch phase {
            case .menstrual: return "Menstrual"
            case .follicular: return "Follicular"
            case .ovulation: return "Ovulation"
            case .luteal: return "Luteal"
            }
        }

        public static func line(_ phase: Phase) -> String {
            switch phase {
            case .menstrual: return "Rest and warmth are welcome."
            case .follicular: return "Energy is climbing."
            case .ovulation: return "Often a bright, social stretch."
            case .luteal: return "Winding down, turning inward."
            }
        }
    }

    public enum Day {
        public static func title(_ day: Int) -> String { "Day \(day)" }
        public static func ofCycle(_ day: Int, length: Int) -> String { "Day \(day) of about \(length)" }
    }

    public enum ConfidenceText {
        public static func label(_ confidence: Confidence) -> String {
            switch confidence {
            case .high: return "Steady pattern"
            case .medium: return "Good estimate"
            case .low: return "Loose estimate"
            }
        }

        public static func explanation(_ confidence: Confidence) -> String {
            switch confidence {
            case .high: return "Recent cycles have been very consistent, so this is a solid read."
            case .medium: return "This is a reasonable estimate. It sharpens as more cycles are noted."
            case .low: return "Cycles vary, and that is completely normal. Treat this as a rough guide."
            }
        }

        public static let phaseEstimate = "Phase estimate"
        public static let phaseUncertain = "Phase uncertain"
        public static let phaseUncertainDetail = "Not enough to go on right now, and that is okay."
    }

    public enum NextPeriod {
        public static let title = "Next period"
        public static func around(_ from: String, _ to: String) -> String { "Likely around \(from) to \(to)" }
        public static let runningBehind = "Running a little behind, which is normal."
        public static let noEstimate = "Note a period start and an estimate will appear here."
    }

    public enum Shade {
        public static let white = "White"
        public static let blush = "Blush"
        public static let softPink = "Soft pink"
        public static let rose = "Rose"
        public static let red = "Red"
        public static let deepRed = "Deep red"
        public static func accessibility(_ shade: String) -> String { "Today's colour is \(shade.lowercased())" }
    }

    public enum Widget {
        public static let displayName = "Cycle Companion"
        public static let description = "A gentle glance at today's phase."
        public static let notLinkedTitle = "Not linked yet"
        public static let notLinkedMessage = "Open the app to accept an invite."
        public static let pausedTitle = "Taking a pause"
        public static let pausedMessage = "Sharing is paused for now."
        public static let staleTitle = "Catching up"
        public static let staleMessage = "Waiting for a fresh update."
        public static let colorOnlyTitle = "Today"
        public static let inlineNotLinked = "Cycle Companion"
        public static let inlinePaused = "Sharing paused"
        public static let inlineStale = "Waiting for an update"
    }

    public enum Onboarding {
        public static let welcomeTitle = "Welcome to Cycle Companion"
        public static let welcomeBody = "A warm, simple way to share where you are in your cycle with someone you trust, and to learn the phases together."
        public static let chooseRole = "How will you use the app?"
        public static let sharerTitle = "I'm sharing my cycle"
        public static let sharerBody = "You own the data. You choose what is shared, and you can pause or stop at any time."
        public static let viewerTitle = "Someone is sharing with me"
        public static let viewerBody = "You will see only what they choose to share, and learn the phases along the way."
        public static let continueButton = "Continue"
        public static let healthTitle = "Read from Apple Health"
        public static let healthBody = "Cycle Companion can read period days from Apple Health so you never have to log here. The raw data stays on this iPhone. Only a tiny summary is ever shared, and only if you choose to share."
        public static let healthAllow = "Connect Apple Health"
        public static let healthSkip = "Not now"
        public static let typicalLengthTitle = "Typical cycle length"
        public static let typicalLengthBody = "If you know yours, set it here. Otherwise we will learn it gently from your history."
        public static let typicalLengthAuto = "Learn from my history"
        public static func typicalLengthDays(_ days: Int) -> String { "\(days) days" }
        public static let done = "All set"
    }

    public enum Sharer {
        public static let todayTitle = "Today"
        public static let logStart = "Period started today"
        public static let logStartOtherDay = "Started on another day"
        public static let logSaved = "Noted. Thank you."
        public static let logUndo = "Undo"
        public static let noDataTitle = "Nothing to show yet"
        public static let noDataBody = "Connect Apple Health or note when your last period started, and we will take it from there."
        public static let historyTitle = "Noted period starts"
        public static let historyEmpty = "No period starts noted yet."
        public static let historyFromHealth = "From Apple Health"
        public static let historyManual = "Noted here"
        public static let tidbitTitle = "Today's little fact"
    }

    public enum Sharing {
        public static let title = "Sharing"
        public static let notSharingTitle = "You are not sharing"
        public static let notSharingBody = "Invite someone you trust. They will see only the summary you choose, never your Health data."
        public static let invite = "Invite someone"
        public static let manage = "Manage who can see"
        public static let detailTitle = "What they see"
        public static let pauseTitle = "Pause sharing"
        public static let pauseBody = "Their widget goes neutral until you resume. Nothing else is shown."
        public static let stop = "Stop sharing"
        public static let stopConfirmTitle = "Stop sharing?"
        public static let stopConfirmBody = "This removes the shared summary from iCloud. Their widget returns to a neutral state. You can invite again any time."
        public static let stopConfirmAction = "Stop sharing"
        public static let cancel = "Cancel"
        public static let previewTitle = "Their view right now"
        public static let whatIsNeverShared = "Never shared: your Health data, period dates, check-ins, or anything you note here."
        public static let iCloudUnavailable = "Sign in to iCloud in Settings to share."
        public static let shareTitle = "Cycle Companion"
        public static let genericError = "That did not go through. Please try again in a moment."

        public static func detailName(_ detail: ShareDetail) -> String {
            switch detail {
            case .dayAndPhase: return "Day, phase and colour"
            case .phaseOnly: return "Phase and colour"
            case .colorOnly: return "Colour only"
            }
        }

        public static func detailExplanation(_ detail: ShareDetail) -> String {
            switch detail {
            case .dayAndPhase: return "They see the cycle day, the phase name and the colour."
            case .phaseOnly: return "They see the phase name and the colour, but no day number."
            case .colorOnly: return "They see only a colour, from white to deep red."
            }
        }
    }

    public enum Viewer {
        public static let notLinkedTitle = "Waiting for an invite"
        public static let notLinkedBody = "Ask your partner to invite you from their Cycle Companion app, then open the link they send."
        public static let pausedTitle = "Sharing is paused"
        public static let pausedBody = "They have paused sharing for now. That is their call, and it is a good one to respect."
        public static let staleTitle = "Catching up"
        public static let staleBody = "No fresh update for a little while. It will refresh on its own."
        public static let learnTitle = "Learn the phases"
        public static let aboutPhase = "About this phase"
        public static let howToHelp = "How to be a good partner"
        public static let whatIsHappening = "What is happening"
        public static let mightFeelLike = "What it might feel like"
        public static let addWidgetTitle = "Add the widget"
        public static let addWidgetBody = "Touch and hold your Home Screen or Lock Screen, tap Edit, and add Cycle Companion."
        public static let unlink = "Remove this link"
        public static let unlinkConfirm = "This removes the shared summary from this iPhone."
        public static func updated(_ relative: String) -> String { "Updated \(relative)" }
    }

    public enum CheckIn {
        public static let title = "Checking in"
        public static let body = "Anything to note today?"
        public static let actionLog = "Period started"
        public static let actionOpen = "Open"
        public static let cardDismiss = "Not now"
        public static let settingsTitle = "Check-ins"
        public static let settingsFooter = "Check-ins stay on this iPhone. Nobody you share with can see them, or whether you answered."

        public static func toneName(_ tone: CheckInTone) -> String {
            switch tone {
            case .silent: return "Silent"
            case .gentle: return "Gentle"
            case .regular: return "Regular"
            }
        }

        public static func toneExplanation(_ tone: CheckInTone) -> String {
            switch tone {
            case .silent: return "No notifications. A small note appears in the app, only if you open it."
            case .gentle: return "One quiet notification, no sound, a couple of days after your expected window."
            case .regular: return "One notification the day after your expected window."
            }
        }
    }

    public enum Settings {
        public static let title = "Settings"
        public static let highContrast = "High-contrast widget"
        public static let highContrastFooter = "Uses strong black and white with the phase and day always written out, instead of the colour scale."
        public static let showTidbit = "Show a friendly line on the widget"
        public static let cycleSection = "Your cycle"
        public static let periodLength = "Typical period length"
        public static let healthSection = "Apple Health"
        public static let healthConnected = "Reading period days from Apple Health"
        public static let healthConnect = "Connect Apple Health"
        public static let privacySection = "Privacy"
        public static let privacyBody = "Your Health data never leaves this iPhone. Sharing sends a tiny summary through your own iCloud, with no analytics and no third parties."
        public static let deleteEverything = "Delete everything"
        public static let deleteConfirmTitle = "Delete everything?"
        public static let deleteConfirmBody = "This removes what you noted here and the shared summary in iCloud. Apple Health is not touched."
        public static let deleteConfirmAction = "Delete"
        public static let switchRole = "Switch role"
        public static let about = "Cycle Companion offers general information, not medical advice."
    }

    public enum Tabs {
        public static let today = "Today"
        public static let sharing = "Sharing"
        public static let learn = "Learn"
        public static let settings = "Settings"
    }
}
