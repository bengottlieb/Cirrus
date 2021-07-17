//
//  CKDatabase.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

public extension CKDatabase {
	func save(record: CKRecord) async throws {
		let op = CKModifyRecordsOperation(recordsToSave: [record])
		_ = try await op.save(in: self)
	}

	func delete(record: CKRecord) async throws {
		let op = CKModifyRecordsOperation(recordIDsToDelete: [record.recordID])
		_ = try await op.delete(from: self)
	}
}
