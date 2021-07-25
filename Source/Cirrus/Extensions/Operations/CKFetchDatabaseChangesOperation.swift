//
//  CKFetchDatabaseChangesOperation.swift
//  CKFetchDatabaseChangesOperation
//
//  Created by Ben Gottlieb on 7/25/21.
//

import CloudKit

public enum CKZoneChange {
	case changed(CKRecordZone.ID)
	case deleted(CKRecordZone.ID)
	case purged(CKRecordZone.ID)
	
	var changedZoneID: CKRecordZone.ID? {
		switch self {
		case .changed(let id): return id
		default: return nil
		}
	}
}

extension CKFetchDatabaseChangesOperation {
	convenience init(database: CKDatabase) {
		self.init(previousServerChangeToken: Cirrus.instance.changeToken(for: database))
		self.database = database
	}
	
	func changedZones() async throws -> [CKZoneChange] {
		var errors: [Error] = []
		var changes: [CKZoneChange] = []
		
		recordZoneWithIDChangedBlock = { id in changes.append(.changed(id)) }
		recordZoneWithIDWasDeletedBlock = { id in changes.append(.changed(id)) }
		recordZoneWithIDWasPurgedBlock = { id in changes.append(.purged(id)) }
		
		return try await withUnsafeThrowingContinuation { continuation in
			self.fetchDatabaseChangesResultBlock = { results in
				switch results {
				case .failure(let error):
					errors.append(error)
					Task() { await Cirrus.instance.handleReceivedError(error) }
					continuation.resume(throwing: Cirrus.MultipleErrors.build(errors: errors))

				case .success(let done):		// (serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool)
					print("Database change token: \(done.serverChangeToken)")
					Task() { await Cirrus.instance.setChangeToken(done.serverChangeToken, for: self.database!) }
					continuation.resume(returning: changes)
				}
			}
			
			self.database?.add(self)
		}
	}
}
