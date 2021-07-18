//
//  CKDatabase.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

public extension CKDatabase {
	func records(ofType type: CKRecord.RecordType, matching predicate: NSPredicate = NSPredicate(value: true), sortedBy: [NSSortDescriptor] = [], in zoneID: CKRecordZone.ID? = nil) -> AsyncRecordSequence {
		let query = CKQuery(recordType: type, predicate: predicate)
		query.sortDescriptors = sortedBy
		
		
		let seq = AsyncRecordSequence(query: query, in: self, zoneID: zoneID)
		seq.start()
		return seq
	}
	
	func save(records: [CKRecord], atomically: Bool = true, conflictResolver: ConflictResolver = ConflictResolverNewerWins()) async throws {
		let op = CKModifyRecordsOperation(recordsToSave: records)
		do {
			try await op.save(in: self)
		} catch {
			if let updatedRecords = try await conflictResolver.resolve(error: error, in: records, database: self) {
				try await save(records: updatedRecords, atomically: atomically, conflictResolver: conflictResolver)
			} else {
				throw error
			}
		}
	}
	
	func save(record: CKRecord?, conflictResolver: ConflictResolver = ConflictResolverNewerWins()) async throws {
		guard let record = record else { return }
		try await save(records: [record], conflictResolver: conflictResolver)
	}

	func delete(record: CKRecord?) async throws {
		guard let record = record else { return }
		let op = CKModifyRecordsOperation(recordIDsToDelete: [record.recordID])
		_ = try await op.delete(from: self)
	}
	
	func fetchRecord(withID id: CKRecord.ID) async throws -> CKRecord? {
		do {
			return try await record(for: id)
		} catch let error as CKError {
			switch error.code {
			case .unknownItem:
				return nil
				
			default:
				throw error
			}
		}
	}
}
