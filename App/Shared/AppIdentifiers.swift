import Foundation

/// The identifiers you must change to your own before building.
/// Keep them in step with project.yml and the two .entitlements files.
enum AppIdentifiers {
    static let appGroup = "group.com.example.cyclecompanion"
    static let cloudContainer = "iCloud.com.example.cyclecompanion"
    static let widgetKind = "CycleCompanionWidget"
}

enum Role: String {
    case sharer, viewer
}
