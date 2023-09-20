//
//  CKDatabaseCache+Fetch.swift
//
//
//  Created by Ben Gottlieb on 6/25/23.
//

import CloudKit

extension CKDatabaseCache {
	public func pullChanges(in zoneID: CKRecordZone.ID? = nil) async {
		do {
			if isPullingChanges { return }
			isPullingChanges = true
			
			cirrus_log("Starting pull changes in \(scope.name): \(zoneID?.zoneName ?? "--")")
			let recordChanges: RecordChanges
			
			if let zoneID {
				recordChanges = try await fetchChanges(in: scope, zoneID: zoneID)
			} else {
				recordChanges = try await fetchAllZoneChanges()
			}
			
			process(changes: recordChanges)
			cirrus_log("Finished pull changes in \(scope.name): \(zoneID?.zoneName ?? "--")")
		} catch {
			cirrus_log("Failing pull changes in \(scope.name): \(zoneID?.zoneName ?? "--"): \(error)")
		}
		isPullingChanges = false
	}
	
	func process(changes: RecordChanges) {
		if !changes.deleted.isEmpty || !changes.modified.isEmpty { cirrus_log("\(changes.deleted.count) records deleted from \(scope.name), \(changes.modified.count) changed") }
	
		for deleted in changes.deleted {
			uncache(deleted)
			container.delegate?.didRemoveRemoteRecord(recordID: deleted, in: scope)
		}
		
		for zone in changes.deletedZones {
			for recordID in records.keys {
				if recordID.zoneID == zone {
					uncache(recordID)
					container.delegate?.didRemoveRemoteRecord(recordID: recordID, in: scope)
				}
			}
		}
		
		load(records: changes.modified)
	}
	
	func fetchAllZoneChanges() async throws -> RecordChanges {
		let changes: (modifications: [CKDatabase.DatabaseChange.Modification], deletions: [CKDatabase.DatabaseChange.Deletion], changeToken: CKServerChangeToken, moreComing: Bool) = try await withCheckedThrowingContinuation { continuation in
			scope.database.fetchDatabaseChanges(since: container.changeTokens.changeToken(for: scope.database)) { results in
				//			Result<(modifications: [CKDatabase.DatabaseChange.Modification], deletions: [CKDatabase.DatabaseChange.Deletion], changeToken: CKServerChangeToken, moreComing: Bool), Error> in
				
				switch results {
				case .success(let modifications):
					continuation.resume(returning: modifications)
					
				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
		}
		
		var returnedChanges = RecordChanges()
		returnedChanges.deletedZones = changes.deletions.map { $0.zoneID }
		container.changeTokens.setChangeToken(changes.changeToken, for: scope.database)
		for change in changes.modifications {
			returnedChanges = returnedChanges + (try await fetchChanges(in: scope, zoneID: change.zoneID))
		}
		
		return returnedChanges
	}
	
	func fetchChanges(in scope: CKDatabase.Scope, zoneID: CKRecordZone.ID) async throws -> RecordChanges {
		return try await withCheckedThrowingContinuation { continuation in
			scope.database.fetchRecordZoneChanges(inZoneWith: zoneID, since: container.changeTokens.changeToken(for: zoneID)) { results in
				
//				Result<(modificationResultsByID: [CKRecord.ID : Result<CKDatabase.RecordZoneChange.Modification, Error>], deletions: [CKDatabase.RecordZoneChange.Deletion], changeToken: CKServerChangeToken, moreComing: Bool), Error> in

				switch results {
				case .success(let modifications):
					var changes = RecordChanges()
					
					for result in modifications.modificationResultsByID.values {
						switch result {
						case .success(let record): changes.modified.append(record.record)
						case .failure(let error): changes.errors.append(error)
						}
					}
					
					for deletion in modifications.deletions {
						changes.deleted.append(deletion.recordID)
					}
					
					continuation.resume(returning: changes)

				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
		}

	}


	struct RecordChanges {
		public var modified: [CKRecord] = []
		public var deleted: [CKRecord.ID] = []
		public var errors: [Error] = []
		public var deletedZones: [CKRecordZone.ID] = []
		
		public static func +(lhs: Self, rhs: Self) -> RecordChanges {
			.init(modified: lhs.modified + rhs.modified, deleted: lhs.deleted + rhs.deleted, errors: lhs.errors + rhs.errors, deletedZones: lhs.deletedZones + rhs.deletedZones)
		}
	}

}
