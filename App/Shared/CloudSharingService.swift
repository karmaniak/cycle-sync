import CloudKit
import CycleCore

/// CloudKit sharing with no custom backend.
///
/// The Sharer keeps one record (the redacted summary) in a dedicated zone of her
/// private database and shares that zone with a CKShare. The Viewer reads it from
/// his shared database. The Viewer has read-only access and nothing to query:
/// what is not in the record does not exist for him.
struct CloudSharingService {
    static let zoneName = "CycleShare"
    static let recordType = "SharedSummary"
    static let recordName = "summary"
    static let payloadKey = "payload"
    static let subscriptionID = "shared-summary-changes"

    let container: CKContainer

    init(container: CKContainer = CKContainer(identifier: AppIdentifiers.cloudContainer)) {
        self.container = container
    }

    private var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
    }

    private var shareID: CKRecord.ID {
        CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
    }

    func isAccountAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    // MARK: Sharer

    /// Writes the summary, replacing whatever was there.
    func publish(_ snapshot: SharedSnapshot) async throws {
        let database = container.privateCloudDatabase
        _ = try await database.modifyRecordZones(saving: [CKRecordZone(zoneID: zoneID)], deleting: [])
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: Self.recordName, zoneID: zoneID))
        record[Self.payloadKey] = try snapshot.encoded() as NSData
        let result = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
        for (_, outcome) in result.saveResults { _ = try outcome.get() }
    }

    /// The existing share, if the Sharer has created one.
    func existingShare() async throws -> CKShare? {
        do {
            return try await container.privateCloudDatabase.record(for: shareID) as? CKShare
        } catch let error as CKError where error.code == .unknownItem || error.code == .zoneNotFound {
            return nil
        }
    }

    /// Returns the share to hand to UICloudSharingController, creating it if needed.
    /// Invite-only, read-only: nobody can find it without being invited.
    func prepareShare(publishing snapshot: SharedSnapshot) async throws -> CKShare {
        try await publish(snapshot)
        if let share = try await existingShare() { return share }
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = Copy.Sharing.shareTitle as CKRecordValue
        share.publicPermission = .none
        let result = try await container.privateCloudDatabase.modifyRecords(saving: [share], deleting: [])
        for (_, outcome) in result.saveResults { _ = try outcome.get() }
        return share
    }

    /// Number of people (other than the owner) who have been invited or have accepted.
    func viewerCount() async -> Int {
        guard let share = try? await existingShare() else { return 0 }
        return share.participants.filter { $0.role != .owner }.count
    }

    /// Revocation: deleting the zone deletes the summary record and the share with it.
    func stopSharing() async throws {
        do {
            _ = try await container.privateCloudDatabase.modifyRecordZones(saving: [], deleting: [zoneID])
        } catch let error as CKError where error.code == .zoneNotFound {
            return
        }
    }

    // MARK: Viewer

    func accept(_ metadata: CKShare.Metadata) async throws {
        _ = try await container.accept(metadata)
    }

    private func sharedZones() async throws -> [CKRecordZone] {
        try await container.sharedCloudDatabase.allRecordZones().filter { $0.zoneID.zoneName == Self.zoneName }
    }

    /// The summary shared with this person, or nil when nothing is shared (never linked, or revoked).
    func fetchShared() async throws -> SharedSnapshot? {
        let database = container.sharedCloudDatabase
        for zone in try await sharedZones() {
            let id = CKRecord.ID(recordName: Self.recordName, zoneID: zone.zoneID)
            do {
                let record = try await database.record(for: id)
                if let data = record[Self.payloadKey] as? Data {
                    return try SharedSnapshot.decode(data)
                }
            } catch let error as CKError where error.code == .unknownItem || error.code == .zoneNotFound {
                continue
            }
        }
        return nil
    }

    /// Silent pushes whenever the shared summary changes, so the widget stays fresh.
    func subscribeToSharedChanges() async throws {
        let subscription = CKDatabaseSubscription(subscriptionID: Self.subscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        _ = try await container.sharedCloudDatabase.modifySubscriptions(saving: [subscription], deleting: [])
    }

    /// The Viewer removes himself from the share.
    func leaveShared() async throws {
        let database = container.sharedCloudDatabase
        for zone in try await sharedZones() {
            let id = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone.zoneID)
            _ = try await database.modifyRecords(saving: [], deleting: [id])
        }
    }
}
