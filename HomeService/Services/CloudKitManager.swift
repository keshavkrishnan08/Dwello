import CloudKit
import SwiftUI

@Observable
class CloudKitManager {
    static let shared = CloudKitManager()

    let container = CKContainer(identifier: "iCloud.com.dwillo.com")
    var iCloudAvailable = false
    var syncStatus: SyncStatus = .idle
    private var syncTask: Task<Void, Never>?

    enum SyncStatus: Equatable {
        case idle, syncing, synced, error(String)
    }

    private enum RT {
        static let log = "LogEntry"
        static let contractor = "Contractor"
        static let reminder = "Reminder"
        static let appliance = "Appliance"
    }

    init() {
        Task { await checkStatus() }
    }

    // MARK: - Status

    @MainActor
    func checkStatus() async {
        do {
            let status = try await container.accountStatus()
            iCloudAvailable = (status == .available)
        } catch {
            iCloudAvailable = false
            print("CloudKit status: \(error.localizedDescription)")
        }
    }

    // MARK: - Debounced Sync (prevents flooding)

    func debouncedSync(appStore: AppStore) {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await syncAll(appStore: appStore)
        }
    }

    // MARK: - Full Sync (push + pull)

    func syncAll(appStore: AppStore) async {
        guard iCloudAvailable else { return }
        await MainActor.run { syncStatus = .syncing }

        do {
            // Push local → cloud (upsert)
            try await batchSave(appStore.logs.map { logToRecord($0) })
            try await batchSave(appStore.contractors.map { contractorToRecord($0) })
            try await batchSave(appStore.reminders.map { reminderToRecord($0) })
            try await batchSave(appStore.appliances.map { applianceToRecord($0) })

            await MainActor.run { syncStatus = .synced }
        } catch {
            await MainActor.run { syncStatus = .error(error.localizedDescription) }
            print("CloudKit sync error: \(error)")
        }
    }

    // MARK: - Pull from cloud (for restore / new device)

    func pullAll() async -> (logs: [LogEntry], contractors: [Contractor], reminders: [Reminder], appliances: [Appliance]) {
        guard iCloudAvailable else { return ([], [], [], []) }

        async let l = fetchAll(RT.log, mapper: recordToLog)
        async let c = fetchAll(RT.contractor, mapper: recordToContractor)
        async let r = fetchAll(RT.reminder, mapper: recordToReminder)
        async let a = fetchAll(RT.appliance, mapper: recordToAppliance)

        return await (l, c, r, a)
    }

    // MARK: - Batch Save (upsert)

    private func batchSave(_ records: [CKRecord]) async throws {
        guard !records.isEmpty else { return }
        let db = container.privateCloudDatabase

        // CloudKit max 400 per operation
        for chunk in records.chunked(into: 400) {
            let (saveResults, _) = try await db.modifyRecords(saving: chunk, deleting: [], savePolicy: .changedKeys)
            for (_, result) in saveResults {
                if case .failure(let error) = result {
                    print("CloudKit save error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Generic Fetch

    private func fetchAll<T>(_ recordType: String, mapper: @escaping (CKRecord) -> T?) async -> [T] {
        let db = container.privateCloudDatabase
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))

        do {
            let (results, _) = try await db.records(matching: query, resultsLimit: 500)
            return results.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return mapper(record)
            }
        } catch {
            print("CloudKit fetch \(recordType): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Delete

    func deleteRecord(id: UUID) async {
        guard iCloudAvailable else { return }
        let recordID = CKRecord.ID(recordName: id.uuidString)
        _ = try? await container.privateCloudDatabase.deleteRecord(withID: recordID)
    }

    // MARK: - Record Mapping: LogEntry

    private func logToRecord(_ log: LogEntry) -> CKRecord {
        let record = CKRecord(recordType: RT.log, recordID: CKRecord.ID(recordName: log.id.uuidString))
        record["homeId"] = log.homeId.uuidString
        record["category"] = log.category.rawValue
        record["title"] = log.title
        record["date"] = log.date
        if let cost = log.cost { record["cost"] = cost as NSNumber }
        record["priority"] = log.priority.rawValue
        record["recurringInterval"] = log.recurringInterval?.rawValue
        record["notes"] = log.notes
        record["contractorId"] = log.contractorId?.uuidString
        return record
    }

    private func recordToLog(_ record: CKRecord) -> LogEntry? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let homeIdStr = record["homeId"] as? String, let homeId = UUID(uuidString: homeIdStr),
              let catStr = record["category"] as? String, let category = HomeCategory(rawValue: catStr),
              let title = record["title"] as? String,
              let date = record["date"] as? Date,
              let priStr = record["priority"] as? String, let priority = Priority(rawValue: priStr)
        else { return nil }

        return LogEntry(
            id: id, homeId: homeId, category: category, title: title, date: date,
            cost: (record["cost"] as? NSNumber)?.doubleValue,
            priority: priority,
            recurringInterval: (record["recurringInterval"] as? String).flatMap { RecurringInterval(rawValue: $0) },
            notes: record["notes"] as? String,
            contractorId: (record["contractorId"] as? String).flatMap { UUID(uuidString: $0) }
        )
    }

    // MARK: - Record Mapping: Contractor

    private func contractorToRecord(_ c: Contractor) -> CKRecord {
        let record = CKRecord(recordType: RT.contractor, recordID: CKRecord.ID(recordName: c.id.uuidString))
        record["userId"] = c.userId.uuidString
        record["name"] = c.name
        record["phone"] = c.phone
        record["email"] = c.email
        record["specialty"] = c.specialty?.rawValue
        record["rating"] = c.rating as NSNumber
        return record
    }

    private func recordToContractor(_ record: CKRecord) -> Contractor? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let userIdStr = record["userId"] as? String, let userId = UUID(uuidString: userIdStr),
              let name = record["name"] as? String,
              let rating = (record["rating"] as? NSNumber)?.intValue
        else { return nil }

        return Contractor(
            id: id, userId: userId, name: name,
            phone: record["phone"] as? String,
            email: record["email"] as? String,
            specialty: (record["specialty"] as? String).flatMap { HomeCategory(rawValue: $0) },
            rating: rating
        )
    }

    // MARK: - Record Mapping: Reminder

    private func reminderToRecord(_ r: Reminder) -> CKRecord {
        let record = CKRecord(recordType: RT.reminder, recordID: CKRecord.ID(recordName: r.id.uuidString))
        record["homeId"] = r.homeId.uuidString
        record["title"] = r.title
        record["dueDate"] = r.dueDate
        record["recurring"] = r.recurring?.rawValue
        record["category"] = r.category.rawValue
        record["completedAt"] = r.completedAt
        return record
    }

    private func recordToReminder(_ record: CKRecord) -> Reminder? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let homeIdStr = record["homeId"] as? String, let homeId = UUID(uuidString: homeIdStr),
              let title = record["title"] as? String,
              let dueDate = record["dueDate"] as? Date,
              let catStr = record["category"] as? String, let category = HomeCategory(rawValue: catStr)
        else { return nil }

        return Reminder(
            id: id, homeId: homeId, title: title, dueDate: dueDate,
            recurring: (record["recurring"] as? String).flatMap { RecurringInterval(rawValue: $0) },
            category: category,
            completedAt: record["completedAt"] as? Date
        )
    }

    // MARK: - Record Mapping: Appliance

    private func applianceToRecord(_ a: Appliance) -> CKRecord {
        let record = CKRecord(recordType: RT.appliance, recordID: CKRecord.ID(recordName: a.id.uuidString))
        record["homeId"] = a.homeId.uuidString
        record["name"] = a.name
        record["make"] = a.make
        record["model"] = a.model
        record["purchaseDate"] = a.purchaseDate
        record["warrantyExpiry"] = a.warrantyExpiry
        record["manualURL"] = a.manualURL
        return record
    }

    private func recordToAppliance(_ record: CKRecord) -> Appliance? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let homeIdStr = record["homeId"] as? String, let homeId = UUID(uuidString: homeIdStr),
              let name = record["name"] as? String
        else { return nil }

        return Appliance(
            id: id, homeId: homeId, name: name,
            make: record["make"] as? String,
            model: record["model"] as? String,
            purchaseDate: record["purchaseDate"] as? Date,
            warrantyExpiry: record["warrantyExpiry"] as? Date,
            manualURL: record["manualURL"] as? String
        )
    }
}

// MARK: - Array chunking helper
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
