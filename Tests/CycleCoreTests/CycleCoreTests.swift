import XCTest
@testable import CycleCore

private var utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

/// Period starts `count` cycles back from `last`, with the given cycle lengths (oldest first).
private func starts(endingOn last: Date, lengths: [Int]) -> [Date] {
    var result = [last]
    for length in lengths.reversed() {
        result.insert(utc.date(byAdding: .day, value: -length, to: result[0])!, at: 0)
    }
    return result
}

final class CycleEngineTests: XCTestCase {
    let engine = CycleEngine(calendar: utc)

    func testNoStartsMeansNoEstimate() {
        XCTAssertNil(engine.estimate(periodStarts: [], today: date(2026, 3, 1)))
    }

    func testFutureStartsAreIgnored() {
        XCTAssertNil(engine.estimate(periodStarts: [date(2026, 3, 5)], today: date(2026, 3, 1)))
    }

    func testDayOneIsTheStartDay() {
        let estimate = engine.estimate(periodStarts: [date(2026, 3, 1, hour: 23)], today: date(2026, 3, 1, hour: 1))
        XCTAssertEqual(estimate?.cycleDay, 1)
        XCTAssertEqual(estimate?.phase, .menstrual)
    }

    func testRegularCycleWalksThroughAllFourPhases() {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 28, 28])
        func phase(onDay day: Int) -> Phase? {
            engine.estimate(periodStarts: history, today: utc.date(byAdding: .day, value: day - 1, to: date(2026, 3, 1))!)?.phase
        }
        XCTAssertEqual(phase(onDay: 1), .menstrual)
        XCTAssertEqual(phase(onDay: 5), .menstrual)
        XCTAssertEqual(phase(onDay: 6), .follicular)
        XCTAssertEqual(phase(onDay: 12), .follicular)
        XCTAssertEqual(phase(onDay: 13), .ovulation)
        XCTAssertEqual(phase(onDay: 14), .ovulation)
        XCTAssertEqual(phase(onDay: 15), .ovulation)
        XCTAssertEqual(phase(onDay: 16), .luteal)
        XCTAssertEqual(phase(onDay: 28), .luteal)
    }

    func testRegularHistoryGivesHighConfidenceAndATightButNeverSingleDayWindow() throws {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 29, 28, 28])
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, 3, 10)))
        XCTAssertEqual(estimate.confidence, .high)
        XCTAssertEqual(estimate.cycleLength, 28)
        XCTAssertEqual(estimate.cycleDay, 10)
        XCTAssertLessThan(estimate.nextStartWindow.lowerBound, estimate.nextStartWindow.upperBound)
        XCTAssertEqual(utc.dateComponents([.day], from: estimate.nextStartWindow.lowerBound, to: estimate.nextStartWindow.upperBound).day, 2)
        XCTAssertFalse(estimate.isRunningBehind)
    }

    func testLearnsCycleLengthFromHistory() throws {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [31, 32, 31])
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, 3, 2)))
        XCTAssertEqual(estimate.cycleLength, 31)
        // Ovulation is placed about fourteen days before the next start, not on day 14.
        XCTAssertEqual(CycleEngine.ovulationDay(cycleLength: 31, periodLength: 5), 17)
    }

    func testSharersOwnTypicalLengthWinsOverHistory() throws {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 28])
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, typicalCycleLength: 30, today: date(2026, 3, 2)))
        XCTAssertEqual(estimate.cycleLength, 30)
    }

    func testSingleStartFallsBackToDefaultsWithLowConfidence() throws {
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: [date(2026, 3, 1)], today: date(2026, 3, 8)))
        XCTAssertEqual(estimate.cycleLength, 28)
        XCTAssertEqual(estimate.confidence, .low)
    }

    func testSingleStartWithHerOwnNumberIsMediumConfidence() throws {
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: [date(2026, 3, 1)], typicalCycleLength: 27, today: date(2026, 3, 8)))
        XCTAssertEqual(estimate.confidence, .medium)
    }

    func testIrregularHistoryGivesLowConfidenceAndAWideWindow() throws {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [24, 41, 29, 36, 22])
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, 3, 10)))
        XCTAssertEqual(estimate.confidence, .low)
        let width = utc.dateComponents([.day], from: estimate.nextStartWindow.lowerBound, to: estimate.nextStartWindow.upperBound).day ?? 0
        XCTAssertGreaterThanOrEqual(width, 8)
    }

    func testSomewhatVariableHistoryIsMedium() throws {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [27, 30, 28, 31])
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, 3, 10)))
        XCTAssertEqual(estimate.confidence, .medium)
    }

    func testAnUnloggedPeriodDoesNotPoisonTheLearnedLength() throws {
        // 28, 28, then a 56-day gap (one period never logged), then 28.
        let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 56, 28])
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, 3, 2)))
        XCTAssertEqual(estimate.cycleLength, 28)
    }

    func testRunningBehindOnlyAfterTheWindowPlusGrace() throws {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 28, 28])
        // Expected 29 March, window 28 to 30 March, grace two more days.
        func behind(_ month: Int, _ day: Int) throws -> Bool {
            try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, month, day))).isRunningBehind
        }
        XCTAssertFalse(try behind(3, 29))
        XCTAssertFalse(try behind(3, 30))
        XCTAssertFalse(try behind(4, 1))
        XCTAssertTrue(try behind(4, 2))
    }

    func testPastTheWindowStaysLutealWithLowerConfidence() throws {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 28, 28])
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, 4, 3)))
        XCTAssertEqual(estimate.phase, .luteal)
        XCTAssertEqual(estimate.confidence, .medium)
    }

    func testVeryOldLastStartGivesNoEstimateRatherThanAGuess() {
        let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28])
        XCTAssertNotNil(engine.estimate(periodStarts: history, today: date(2026, 4, 25)))
        XCTAssertNil(engine.estimate(periodStarts: history, today: date(2026, 4, 26)))
    }

    func testShortCycleStillHasEveryPhaseInOrder() {
        var seen: [Phase] = []
        for day in 1...21 {
            let phase = CycleEngine.phase(cycleDay: day, cycleLength: 21, periodLength: 5)
            if seen.last != phase { seen.append(phase) }
        }
        XCTAssertEqual(seen, [.menstrual, .follicular, .ovulation, .luteal])
    }

    func testNearDuplicateStartsFromTwoSourcesCollapse() throws {
        let history = [date(2026, 2, 1), date(2026, 3, 1), date(2026, 3, 2)]
        let estimate = try XCTUnwrap(engine.estimate(periodStarts: history, today: date(2026, 3, 3)))
        XCTAssertEqual(estimate.cycleDay, 3)
    }
}

final class PeriodDetectorTests: XCTestCase {
    func testGroupsConsecutiveFlowDaysIntoPeriods() {
        let flow = [1, 2, 3, 4, 5].map { date(2026, 1, $0) } + [29, 30, 31].map { date(2026, 1, $0) } + [date(2026, 2, 1)]
        XCTAssertEqual(
            PeriodDetector.periodStarts(fromFlowDays: flow.shuffled(), calendar: utc),
            [utc.startOfDay(for: date(2026, 1, 1)), utc.startOfDay(for: date(2026, 1, 29))]
        )
    }

    func testToleratesASkippedDayInsideAPeriod() {
        let flow = [1, 2, 4, 5].map { date(2026, 1, $0) }
        XCTAssertEqual(PeriodDetector.periodStarts(fromFlowDays: flow, calendar: utc).count, 1)
    }

    func testSpottingSoonAfterAPeriodIsNotANewPeriod() {
        let flow = [1, 2, 3, 4].map { date(2026, 1, $0) } + [date(2026, 1, 9)]
        XCTAssertEqual(PeriodDetector.periodStarts(fromFlowDays: flow, calendar: utc).count, 1)
    }

    func testDuplicateSamplesOnOneDayAreHarmless() {
        let flow = [date(2026, 1, 1, hour: 8), date(2026, 1, 1, hour: 20), date(2026, 1, 2)]
        XCTAssertEqual(PeriodDetector.periodStarts(fromFlowDays: flow, calendar: utc).count, 1)
    }

    func testEmptyInput() {
        XCTAssertTrue(PeriodDetector.periodStarts(fromFlowDays: [], calendar: utc).isEmpty)
    }
}

final class ColorScaleTests: XCTestCase {
    func testDeepestOnDayOneAndWhiteJustAfterThePeriod() {
        XCTAssertEqual(ColorScale.position(cycleDay: 1, cycleLength: 28, periodLength: 5), 1.0)
        XCTAssertEqual(ColorScale.position(cycleDay: 6, cycleLength: 28, periodLength: 5), 0.0)
        XCTAssertEqual(ColorScale.color(at: 0), RGB(hex: 0xFFFFFF))
        XCTAssertEqual(ColorScale.color(at: 1), RGB(hex: 0x8E0E2E))
    }

    func testWarmsSteadilyTowardTheNextPeriod() {
        let positions = (6...28).map { ColorScale.position(cycleDay: $0, cycleLength: 28, periodLength: 5) }
        XCTAssertEqual(positions, positions.sorted())
        XCTAssertGreaterThan(positions.last!, 0.85)
        XCTAssertLessThan(positions.last!, 1.0)
    }

    func testDoesNotKeepDeepeningWhenThePeriodArrivesLaterThanExpected() {
        let last = ColorScale.position(cycleDay: 28, cycleLength: 28, periodLength: 5)
        XCTAssertEqual(ColorScale.position(cycleDay: 35, cycleLength: 28, periodLength: 5), last)
    }

    func testAlwaysInRange() {
        for length in 15...60 {
            for day in 1...(length * 2) {
                let p = ColorScale.position(cycleDay: day, cycleLength: length, periodLength: 5)
                XCTAssertTrue((0...1).contains(p), "day \(day) of \(length)")
            }
        }
    }

    func testTextIsReadableOnEveryShade() {
        for step in 0...100 {
            let background = ColorScale.color(at: Double(step) / 100)
            let foreground = ColorScale.foreground(on: background)
            XCTAssertGreaterThanOrEqual(background.contrast(with: foreground), 4.5, "position \(step)")
        }
        XCTAssertGreaterThanOrEqual(ColorScale.neutral.contrast(with: ColorScale.ink), 7)
    }
}

final class SnapshotTests: XCTestCase {
    let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 28, 28])

    private func snapshot(_ detail: ShareDetail, paused: Bool = false, starts: [Date]? = nil) -> SharedSnapshot {
        SnapshotBuilder.make(periodStarts: starts ?? history, typicalCycleLength: nil, detail: detail, paused: paused, now: date(2026, 3, 2), calendar: utc)
    }

    func testFullDetailCarriesDayPhaseConfidenceAndColourForAWeek() {
        let snap = snapshot(.dayAndPhase)
        XCTAssertEqual(snap.days.count, 7)
        XCTAssertEqual(snap.days.first, .init(date: "2026-03-02", cycleDay: 2, phase: .menstrual, confidence: .high, color: 0.93))
        XCTAssertEqual(snap.days.last?.cycleDay, 8)
        XCTAssertEqual(snap.days.last?.phase, .follicular)
    }

    func testPhaseOnlyOmitsTheDayNumber() {
        for day in snapshot(.phaseOnly).days {
            XCTAssertNil(day.cycleDay)
            XCTAssertNotNil(day.phase)
        }
    }

    func testColourOnlyOmitsEverythingElseFromThePayloadItself() throws {
        let snap = snapshot(.colorOnly)
        for day in snap.days {
            XCTAssertNil(day.cycleDay)
            XCTAssertNil(day.phase)
            XCTAssertNil(day.confidence)
            XCTAssertNotNil(day.color)
        }
        let json = String(decoding: try snap.encoded(), as: UTF8.self)
        XCTAssertFalse(json.contains("cycleDay"))
        XCTAssertFalse(json.contains("phase\""))
        XCTAssertFalse(json.contains("menstrual"))
    }

    func testPausedSnapshotCarriesNoCycleInformationAtAll() throws {
        let snap = snapshot(.dayAndPhase, paused: true)
        XCTAssertEqual(snap.status, .paused)
        XCTAssertTrue(snap.days.isEmpty)
    }

    func testPayloadNeverContainsDatesOfPeriodsOrSharerOnlyFields() throws {
        let json = String(decoding: try snapshot(.dayAndPhase).encoded(), as: UTF8.self)
        for forbidden in ["lastPeriodStart", "nextStart", "isRunningBehind", "cycleLength", "2026-03-01", "2026-02-01", "checkIn"] {
            XCTAssertFalse(json.contains(forbidden), forbidden)
        }
    }

    func testRoundTrip() throws {
        let snap = snapshot(.dayAndPhase)
        XCTAssertEqual(try SharedSnapshot.decode(try snap.encoded()), snap)
    }

    func testNoHistoryPublishesHonestlyEmptyDays() {
        let snap = snapshot(.dayAndPhase, starts: [])
        XCTAssertEqual(snap.status, .active)
        XCTAssertTrue(snap.days.allSatisfy { $0.phase == nil && $0.color == nil && $0.cycleDay == nil })
    }
}

final class GlanceTests: XCTestCase {
    let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 28, 28])

    private func snapshot(_ detail: ShareDetail, paused: Bool = false, starts: [Date]? = nil) -> SharedSnapshot {
        SnapshotBuilder.make(periodStarts: starts ?? history, typicalCycleLength: nil, detail: detail, paused: paused, now: date(2026, 3, 2), calendar: utc)
    }

    private func glance(_ snapshot: SharedSnapshot?, on day: Date = date(2026, 3, 2), options: Glance.Options = .init()) -> GlanceContent {
        Glance.content(snapshot: snapshot, on: day, calendar: utc, options: options)
    }

    func testNotLinked() {
        let content = glance(nil)
        XCTAssertEqual(content.kind, .notLinked)
        XCTAssertEqual(content.background, ColorScale.neutral)
    }

    func testPausedIsNeutralAndSaysNothingAboutTheCycle() {
        let content = glance(snapshot(.dayAndPhase, paused: true))
        XCTAssertEqual(content.kind, .paused)
        XCTAssertEqual(content.background, ColorScale.neutral)
        XCTAssertNil(content.phase)
        XCTAssertNil(content.cycleDay)
    }

    func testStaleOnceTheForecastRunsOut() {
        let snap = snapshot(.dayAndPhase)
        XCTAssertEqual(glance(snap, on: date(2026, 3, 8)).kind, .live)
        XCTAssertEqual(glance(snap, on: date(2026, 3, 9)).kind, .stale)
        XCTAssertEqual(glance(snap, on: date(2026, 3, 1)).kind, .stale)
    }

    func testUncertainWhenTheSharerHasNoEstimate() {
        XCTAssertEqual(glance(snapshot(.dayAndPhase, starts: [])).kind, .uncertain)
    }

    func testLiveFullDetail() {
        let content = glance(snapshot(.dayAndPhase))
        XCTAssertEqual(content.kind, .live)
        XCTAssertEqual(content.title, "Day 2")
        XCTAssertEqual(content.subtitle, "Menstrual")
        XCTAssertNotNil(content.message)
        XCTAssertEqual(content.inlineText, "Day 2 · Menstrual")
        XCTAssertEqual(content.foreground, ColorScale.paper)
    }

    func testLivePhaseOnlyShowsPhaseAsTheTitle() {
        let content = glance(snapshot(.phaseOnly))
        XCTAssertEqual(content.title, "Menstrual")
        XCTAssertNil(content.cycleDay)
    }

    func testColourOnlyStillWritesTheShadeOut() {
        let content = glance(snapshot(.colorOnly))
        XCTAssertEqual(content.subtitle, Copy.Shade.deepRed)
        XCTAssertNil(content.message)
        XCTAssertTrue(content.accessibilityLabel.contains("deep red"))
    }

    func testLowConfidenceIsLabelledAsAnEstimate() {
        let irregular = starts(endingOn: date(2026, 3, 1), lengths: [24, 41, 29, 36, 22])
        let content = glance(snapshot(.dayAndPhase, starts: irregular))
        XCTAssertEqual(content.subtitle, "Menstrual · Phase estimate")
    }

    func testHighContrastKeepsTextAndDropsTheColourScale() {
        let content = glance(snapshot(.dayAndPhase), options: .init(highContrast: true))
        XCTAssertEqual(content.background, ColorScale.paper)
        XCTAssertEqual(content.foreground, RGB(hex: 0x000000))
        XCTAssertEqual(content.title, "Day 2")
        XCTAssertEqual(content.subtitle, "Menstrual")
    }

    func testMessageCanBeTurnedOff() {
        XCTAssertNil(glance(snapshot(.dayAndPhase), options: .init(showsMessage: false)).message)
    }

    func testOvulationGetsItsAccent() {
        XCTAssertTrue(glance(SnapshotBuilder.make(periodStarts: history, typicalCycleLength: nil, detail: .dayAndPhase, paused: false, now: date(2026, 3, 14), calendar: utc), on: date(2026, 3, 14)).showsOvulationAccent)
    }
}

final class CheckInTests: XCTestCase {
    let engine = CycleEngine(calendar: utc)
    let history = starts(endingOn: date(2026, 3, 1), lengths: [28, 28, 28, 28])
    // Expected start 29 March; soft window 28 to 30 March.

    private func estimate(_ month: Int, _ day: Int) -> CycleEstimate {
        engine.estimate(periodStarts: history, today: date(2026, month, day))!
    }

    func testSilentToneNeverSchedulesANotification() {
        XCTAssertNil(CheckInPlanner.notificationPlan(estimate: estimate(3, 10), tone: .silent, now: date(2026, 3, 10), calendar: utc))
    }

    func testGentleWaitsTwoDaysPastTheWindow() {
        let plan = CheckInPlanner.notificationPlan(estimate: estimate(3, 10), tone: .gentle, now: date(2026, 3, 10), calendar: utc)
        XCTAssertEqual(plan?.fireDate, date(2026, 4, 1, hour: 10))
    }

    func testRegularWaitsOneDayPastTheWindow() {
        let plan = CheckInPlanner.notificationPlan(estimate: estimate(3, 10), tone: .regular, now: date(2026, 3, 10), calendar: utc)
        XCTAssertEqual(plan?.fireDate, date(2026, 3, 31, hour: 10))
    }

    func testNeverOnOrBeforeThePredictedDayForAnyTone() {
        let expected = date(2026, 3, 29, hour: 23)
        for tone in [CheckInTone.gentle, .regular] {
            let plan = CheckInPlanner.notificationPlan(estimate: estimate(3, 10), tone: tone, now: date(2026, 3, 10), calendar: utc)
            XCTAssertGreaterThan(plan!.fireDate, expected)
        }
    }

    func testNoLateNudgeOnceTheMomentHasPassed() {
        XCTAssertNil(CheckInPlanner.notificationPlan(estimate: estimate(4, 3), tone: .gentle, now: date(2026, 4, 3), calendar: utc))
    }

    func testInAppInvitationFollowsTheSameDelay() {
        XCTAssertFalse(CheckInPlanner.shouldInviteInApp(estimate: estimate(3, 29), tone: .silent, today: date(2026, 3, 29), calendar: utc))
        XCTAssertFalse(CheckInPlanner.shouldInviteInApp(estimate: estimate(3, 31), tone: .silent, today: date(2026, 3, 31), calendar: utc))
        XCTAssertTrue(CheckInPlanner.shouldInviteInApp(estimate: estimate(4, 1), tone: .silent, today: date(2026, 4, 1), calendar: utc))
    }

    func testLoggingAStartClearsThePlanUntilTheNextCycle() {
        let logged = engine.estimate(periodStarts: history + [date(2026, 3, 30)], today: date(2026, 3, 30))!
        XCTAssertFalse(CheckInPlanner.shouldInviteInApp(estimate: logged, tone: .regular, today: date(2026, 3, 30), calendar: utc))
    }
}

final class CopyToneTests: XCTestCase {
    /// Words the design brief rules out, anywhere a person might read them.
    func testEducationAvoidsAlarmingWordsAndRespectsLengthLimits() {
        let banned = ["overdue", "missed", "warning", " late ", " late."]
        for phase in Phase.allCases {
            let guide = Education.guide(for: phase)
            let all = [guide.name, guide.headline, guide.whatIsHappening, guide.mightFeelLike]
                + guide.howToHelp + Education.tidbits(for: phase) + Education.widgetLines(for: phase)
            for text in all {
                for word in banned {
                    XCTAssertFalse(text.lowercased().contains(word), "\"\(text)\" contains \(word)")
                }
            }
            XCTAssertGreaterThanOrEqual(Education.tidbits(for: phase).count, 10)
            XCTAssertTrue(Education.tidbits(for: phase).allSatisfy { $0.count <= 140 })
            XCTAssertTrue(Education.widgetLines(for: phase).allSatisfy { $0.count <= 34 })
        }
    }

    func testDailyTidbitIsStableWithinADayAndChangesTheNext() {
        let a = Education.tidbit(for: .luteal, on: date(2026, 3, 2, hour: 1), calendar: utc)
        let b = Education.tidbit(for: .luteal, on: date(2026, 3, 2, hour: 22), calendar: utc)
        let c = Education.tidbit(for: .luteal, on: date(2026, 3, 3), calendar: utc)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
