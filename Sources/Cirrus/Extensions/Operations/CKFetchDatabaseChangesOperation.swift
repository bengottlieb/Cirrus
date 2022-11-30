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
	
	public var changedZoneID: CKRecordZone.ID? {
		switch self {
		case .changed(let id): return id
		default: return nil
		}
	}
}

public class CirrusFetchDatabaseChangesOperation: CKFetchDatabaseChangesOperation {
	var tokens = Cirrus.instance.localState.changeTokens
	
	public convenience init(database: CKDatabase, tokens: ChangeTokens) {
		self.init(previousServerChangeToken: tokens.changeToken(for: database))
		self.database = database
		self.tokens = tokens
	}
	
	public func changedZones() async throws -> [CKZoneChange] {
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
					Task() { await Cirrus.instance.shouldCancelAfterError(error) }
					continuation.resume(throwing: Cirrus.MultipleErrors.build(errors: errors))

				case .success(let done):		// (serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool)
					print("Database change token: \(done.serverChangeToken)")
					self.tokens.setChangeToken(done.serverChangeToken, for: self.database!)
					continuation.resume(returning: changes)
				}
			}
			
			self.database?.add(self)
		}
	}
}
