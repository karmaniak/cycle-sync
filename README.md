# Cycle Companion

A warm, consent-first iOS app that lets one person (the **Sharer**) share a gentle
summary of where they are in their menstrual cycle with someone they trust (the
**Viewer**), and helps both learn the phases. Built from the *Cycle Companion:
Design Brief and PRD*.

iOS 17+, Swift, SwiftUI, WidgetKit, HealthKit, CloudKit. No custom backend, no
analytics, no third-party SDKs.

## What is here

| Path | What |
| --- | --- |
| `Sources/CycleCore` | Pure-Swift core: cycle engine, colour scale, share payload, check-in rules, widget presentation logic, all copy, education content. Runs anywhere Swift does. |
| `Tests/CycleCoreTests` | Unit tests for the core, covering regular and irregular cycles, privacy redaction, every widget state, check-in timing and tone of copy. |
| `App/CycleCompanion` | The SwiftUI app (Sharer and Viewer modes in one target). |
| `App/CycleWidget` | Home Screen (small, medium) and Lock Screen (inline, circular, rectangular) widgets. |
| `App/Shared` | Code compiled into both app and widget: App Group store, CloudKit service, the glance card. |

## Run it

```sh
swift test                      # core tests, macOS or Linux

brew install xcodegen
cd App && xcodegen generate     # creates CycleCompanion.xcodeproj
open CycleCompanion.xcodeproj
```

Before running on a device, replace `com.example` with your own prefix in three
places: `App/project.yml`, `App/Shared/AppIdentifiers.swift`, and the two
`.entitlements` files. Then pick your team in Xcode and let it create the App
Group and iCloud container. HealthKit and CloudKit sharing need real devices
signed in to iCloud; two different Apple IDs are needed to try the invite flow.

## How it works

**Sharer's iPhone.** Period days are read from Apple Health (read-only), or noted
with one tap. `PeriodDetector` turns flow days into period starts, and
`CycleEngine` turns those into a cycle day, a phase, a confidence level and a soft
range for the next start. Health data is treated as a hint: an unlogged period
does not skew the learned cycle length, and if the last start is too old the
engine says nothing rather than guessing.

**What gets shared.** Only a `SharedSnapshot`: a week of already-redacted day
summaries (day, phase, confidence, colour), trimmed to what the Sharer chose
(day + phase + colour, phase + colour, or colour only). Fields she has not shared
are absent from the payload, not hidden by the Viewer's UI. No period dates, no
cycle length, no check-in activity, no raw samples ever leave the device.

**Sync.** One record in a dedicated zone of the Sharer's private CloudKit
database, shared read-only and invite-only with a zone-wide `CKShare`. Pausing
replaces it with an empty "paused" snapshot. Stopping deletes the zone, which
deletes the record and the share.

**Viewer's iPhone.** Accepting the invite makes the install a Viewer. The app and
the widget read the snapshot from the shared database and draw it. There is no
code path for a Viewer to request anything.

**Widget.** Background runs white → soft pink → deep red; phase and day are
always written as text. States: not linked, paused, catching up (stale),
phase uncertain, and "phase estimate" when confidence is low. A high-contrast
variant drops the colour scale entirely.

**Check-ins.** Local to the Sharer's device. Never on the predicted day: one to
two days after the soft window. Silent by default (an in-app card only).
Dismissing is not an answer and is not recorded or synced.

## Decisions made on the PRD's open questions

- **Colour scale** follows days until the next period: white just after a period
  ends, warming through the cycle, deepest on day one. It stops deepening if a
  period arrives after the expected window, so colour never reads as urgency.
  Ovulation is a small gold dot beside the title rather than a colour.
- **Paused sharing** shows a neutral widget with "Taking a pause", nothing else.
- **Silent / gentle / regular** tones: no notification / one quiet one two days
  after the window / one ordinary one a day after.
- **Sharer's typical cycle length**, when she sets it, wins over learned history.

## Not done yet

- Wrist temperature to refine ovulation timing.
- Contact Poster / Live Activity exploration for call context.
- Education copy has not had an expert accuracy review, which the PRD asks for
  before release.
- Localisation (all strings are in `Copy.swift` and `Education.swift`, English only).

This app offers general information, not medical advice.
