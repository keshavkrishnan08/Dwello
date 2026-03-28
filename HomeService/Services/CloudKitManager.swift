import CloudKit
import SwiftUI

@Observable
class CloudKitManager {
    static let shared = CloudKitManager()

    let container = CKContainer(identifier: "iCloud.dds.HomeService")
    var iCloudAvailable = false
    var syncStatus: SyncStatus = .idle

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case error(String)
    }

    // Record type identifiers
    private enum RecordType {
        static let log = "LogEntry"
        static let contractor = "Contractor"
        static let reminder = "Reminder"
        static let appliance = "Appliance"
        static let home = "Home"
    }

    init() {
        checkiCloudStatus()
    }

    // MARK: - iCloud Status

    func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.iCloudAvailable = (status == .available)
                if let error = error {
                    print("CloudKit status error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Save Records

    func saveLogs(_ logs: [LogEntry]) async {
        guard iCloudAvailable else { return }
        await MainActor.run { syncStatus = .syncing }

        let database = container.privateCloudDatabase

        do {
            for log in logs {
                let record = logToRecord(log)
                try await database.save(record)
            }
            await MainActor.run { syncStatus = .synced }
        } catch {
            await MainActor.run { syncStatus = .error(error.localizedDescription) }
        }
    }

    func saveContractors(_ contractors: [Contractor]) async {
        guard iCloudAvailable else { return }

        let database = container.privateCloudDatabase
        for contractor in contractors {
            let record = contractorToRecord(contractor)
            _ = try? await database.save(record)
        }
    }

    func saveReminders(_ reminders: [Reminder]) async {
        guard iCloudAvailable else { return }

        let database = container.privateCloudDatabase
        for reminder in reminders {
            let record = reminderToRecord(reminder)
            _ = try? await database.save(record)
        }
    }

    func saveAppliances(_ appliances: [Appliance]) async {
        guard iCloudAvailable else { return }

        let database = container.privateCloudDatabase
        for appliance in appliances {
            let record = applianceToRecord(appliance)
            _ = try? await database.save(record)
        }
    }

    // MARK: - Fetch Records

    func fetchLogs() async -> [LogEntry] {
        guard iCloudAvailable else { return [] }

        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: RecordType.log, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 500)
            return results.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return recordToLog(record)
            }
        } catch {
            print("CloudKit fetch error: \(error)")
            return []
        }
    }

    func fetchContractors() async -> [Contractor] {
        guard iCloudAvailable else { return [] }

        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: RecordType.contractor, predicate: NSPredicate(value: true))

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 100)
            return results.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return recordToContractor(record)
            }
        } catch { return [] }
    }

    func fetchReminders() async -> [Reminder] {
        guard iCloudAvailable else { return [] }

        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: RecordType.reminder, predicate: NSPredicate(value: true))

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 200)
            return results.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return recordToReminder(record)
            }
        } catch { return [] }
    }

    func fetchAppliances() async -> [Appliance] {
        guard iCloudAvailable else { return [] }

        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: RecordType.appliance, predicate: NSPredicate(value: true))

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 100)
            return results.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return recordToAppliance(record)
            }
        } catch { return [] }
    }

    // MARK: - Full Sync

    func syncAll(appStore: AppStore) async {
        guard iCloudAvailable else { return }
        await MainActor.run { syncStatus = .syncing }

        // Push local → cloud
        await saveLogs(appStore.logs)
        await saveContractors(appStore.contractors)
        await saveReminders(appStore.reminders)
        await saveAppliances(appStore.appliances)

        await MainActor.run { syncStatus = .synced }
    }

    // MARK: - Delete

    func deleteRecord(id: UUID, type: String) async {
        guard iCloudAvailable else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: id.uuidString)
        _ = try? await database.deleteRecord(withID: recordID)
    }

    // MARK: - Record Mapping: LogEntry

    private func logToRecord(_ log: LogEntry) -> CKRecord {
        let record = CKRecord(recordType: RecordType.log, recordID: CKRecord.ID(recordName: log.id.uuidString))
        record["homeId"] = log.homeId.uuidString
        record["category"] = log.category.rawValue
        record["title"] = log.title
        record["date"] = log.date
        record["cost"] = log.cost as? CKRecordValue
        record["priority"] = log.priority.rawValue
        record["recurringInterval"] = log.recurringInterval?.rawValue
        record["notes"] = log.notes
        record["contractorId"] = log.contractorId?.uuidString
        return record
    }

    private func recordToLog(_ record: CKRecord) -> LogEntry? {
        guard let idStr = record.recordID.recordName as String?,
              let id = UUID(uuidString: idStr),
              let homeIdStr = record["homeId"] as? String,
              let homeId = UUID(uuidString: homeIdStr),
              let categoryStr = record["category"] as? String,
              let category = HomeCategory(rawValue: categoryStr),
              let title = record["title"] as? String,
              let date = record["date"] as? Date,
              let priorityStr = record["priority"] as? String,
              let priority = Priority(rawValue: priorityStr)
        else { return nil }

        let cost = record["cost"] as? Double
        let recurringStr = record["recurringInterval"] as? String
        let recurring = recurringStr.flatMap { RecurringInterval(rawValue: $0) }
        let notes = record["notes"] as? String
        let contractorIdStr = record["contractorId"] as? String
        let contractorId = contractorIdStr.flatMap { UUID(uuidString: $0) }

        return LogEntry(
            id: id, homeId: homeId, category: category, title: title,
            date: date, cost: cost, priority: priority,
            recurringInterval: recurring, notes: notes,
            contractorId: contractorId, photoURLs: []
        )
    }

    // MARK: - Record Mapping: Contractor

    private func contractorToRecord(_ c: Contractor) -> CKRecord {
        let record = CKRecord(recordType: RecordType.contractor, recordID: CKRecord.ID(recordName: c.id.uuidString))
        record["userId"] = c.userId.uuidString
        record["name"] = c.name
        record["phone"] = c.phone
        record["email"] = c.email
        record["specialty"] = c.specialty?.rawValue
        record["rating"] = c.rating
        return record
    }

    private func recordToContractor(_ record: CKRecord) -> Contractor? {
        guard let idStr = record.recordID.recordName as String?,
              let id = UUID(uuidString: idStr),
              let userIdStr = record["userId"] as? String,
              let userId = UUID(uuidString: userIdStr),
              let name = record["name"] as? String,
              let rating = record["rating"] as? Int
        else { return nil }

        let specialtyStr = record["specialty"] as? String
        let specialty = specialtyStr.flatMap { HomeCategory(rawValue: $0) }

        return Contractor(
            id: id, userId: userId, name: name,
            phone: record["phone"] as? String,
            email: record["email"] as? String,
            specialty: specialty, rating: rating
        )
    }

    // MARK: - Record Mapping: Reminder

    private func reminderToRecord(_ r: Reminder) -> CKRecord {
        let record = CKRecord(recordType: RecordType.reminder, recordID: CKRecord.ID(recordName: r.id.uuidString))
        record["homeId"] = r.homeId.uuidString
        record["title"] = r.title
        record["dueDate"] = r.dueDate
        record["recurring"] = r.recurring?.rawValue
        record["category"] = r.category.rawValue
        record["completedAt"] = r.completedAt
        return record
    }

    private func recordToReminder(_ record: CKRecord) -> Reminder? {
        guard let idStr = record.recordID.recordName as String?,
              let id = UUID(uuidString: idStr),
              let homeIdStr = record["homeId"] as? String,
              let homeId = UUID(uuidString: homeIdStr),
              let title = record["title"] as? String,
              let dueDate = record["dueDate"] as? Date,
              let categoryStr = record["category"] as? String,
              let category = HomeCategory(rawValue: categoryStr)
        else { return nil }

        let recurringStr = record["recurring"] as? String
        let recurring = recurringStr.flatMap { RecurringInterval(rawValue: $0) }

        return Reminder(
            id: id, homeId: homeId, title: title, dueDate: dueDate,
            recurring: recurring, category: category,
            completedAt: record["completedAt"] as? Date
        )
    }

    // MARK: - Record Mapping: Appliance

    private func applianceToRecord(_ a: Appliance) -> CKRecord {
        let record = CKRecord(recordType: RecordType.appliance, recordID: CKRecord.ID(recordName: a.id.uuidString))
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
        guard let idStr = record.recordID.recordName as String?,
              let id = UUID(uuidString: idStr),
              let homeIdStr = record["homeId"] as? String,
              let homeId = UUID(uuidString: homeIdStr),
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
