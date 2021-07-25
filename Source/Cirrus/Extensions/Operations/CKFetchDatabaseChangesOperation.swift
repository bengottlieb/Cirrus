//
//  CKFetchDatabaseChangesOperation.swift
//  CKFetchDatabaseChangesOperation
//
//  Created by Ben Gottlieb on 7/25/21.
//

import CloudKit

public enum CKZoneChange {
	case created
	case purged
}

extension CKFetchDatabaseChangesOperation {
	convenience init(database: CKDatabase) {
		self.init(previousServerChangeToken: Cirrus.instance.localState.changeToken(for: database))
	}
	
	func changedZones() async throws -> [CKZoneChange] {
		var errors: [Error] = []
		var changes: [CKZoneChange] = []
		
		return try await withUnsafeThrowingContinuation { continuation in
			self.fetchDatabaseChangesResultBlock = { results in
				switch results {
				case .failure(let error):
					errors.append(error)
					//Cirrus.instance.handleReceivedError(error)
					continuation.resume(throwing: Cirrus.MultipleErrors.build(errors: errors))

				case .success(let done):		// (serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool)
//					Task() {
//						await Cirrus.instance.localState.setChangeToken(done.serverChangeToken, for: self.database!)
//					}
					continuation.resume(returning: changes)
				}
			}
			
			
		}
	}
}
