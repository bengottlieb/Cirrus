//
//  CKRecord+Sharing.swift
//
//
//  Created by Ben Gottlieb on 6/18/23.
//

import Foundation
import CloudKit

public extension CKRecord {
	func isShared(withuserID userID: CKRecord.ID) async throws -> Bool {
		guard let share = try await fetchShare(createIfNeeded: false) else { return false }
		
		return share.participants.contains { $0.userIdentity.userRecordID == userID }
	}
	
	func fetchShare(createIfNeeded: Bool = false) async throws -> CKShare? {
		let actualRecord = try await CKDatabase.private.fetchRecord(withID: recordID) ?? self
		if let shareRecord = try await CKDatabase.private.resolve(reference: actualRecord.share) {
			if let share = shareRecord as? CKShare { return share }
			print("Got a share record, but it's not a CKShare.")
			return nil
		}
		
		if !createIfNeeded { return nil }
		
		let share = CKShare(rootRecord: actualRecord)
		share.publicPermission = .readOnly
		let results = try await CKDatabase.private.modifyRecords(saving: [actualRecord, share], deleting: [])

		if results.saveResults.values.count != 2 { return nil }
		
		return share
	}
}