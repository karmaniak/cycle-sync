import Foundation
import HealthKit

/// Read-only access to period days in Apple Health. Nothing is ever written,
/// and samples never leave this type except as plain dates.
struct HealthKitService {
    private let store = HKHealthStore()
    private var flowType: HKCategoryType { HKCategoryType(.menstrualFlow) }

    /// Raw value of "no flow" (HKCategoryValueMenstrualFlow.none / HKCategoryValueVaginalBleeding.none).
    private static let noFlowValue = 5

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: [flowType])
    }

    /// Days on which flow was recorded since the given date.
    /// Returns an empty list when access was not granted: HealthKit does not reveal read denials.
    func flowDays(since start: Date) async throws -> [Date] {
        guard isAvailable else { return [] }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: flowType, predicate: HKQuery.predicateForSamples(withStart: start, end: nil))],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        return try await descriptor.result(for: store)
            .filter { $0.value != Self.noFlowValue }
            .map(\.startDate)
    }

    /// Calls back when Health gains or loses period data, including in the background.
    func observeChanges(_ onChange: @escaping @Sendable () -> Void) {
        guard isAvailable else { return }
        let query = HKObserverQuery(sampleType: flowType, predicate: nil) { _, completion, error in
            if error == nil { onChange() }
            completion()
        }
        store.execute(query)
        store.enableBackgroundDelivery(for: flowType, frequency: .daily) { _, _ in }
    }
}
