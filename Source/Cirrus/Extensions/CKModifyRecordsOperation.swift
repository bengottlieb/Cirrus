//
//  CKModifyRecordsOperation.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import CloudKit

extension CKModifyRecordsOperation {
	public func save(in database: CKDatabase) async throws -> [CKRecord] {
		assert(recordIDsToDelete.isNotEmpty, "using CKModifyRecordsOperation.save() to delete records is not supported")

		guard let records = recordsToSave, records.isNotEmpty else { return [] }
		
		return try await withUnsafeThrowingContinuation { continuation in
			self.modifyRecordsResultBlock = { result in
				switch result {
				case .success: continuation.resume(returning: records)
				case .failure(let error): continuation.resume(throwing: error)
				}
			}
			database.add(self)
		}
	}
	
	public func delete(from database: CKDatabase) async throws {
		assert(recordsToSave.isNotEmpty, "using CKModifyRecordsOperation.delete() to save records is not supported")

		guard let recordIDs = recordIDsToDelete, recordIDs.isNotEmpty else { return }
		
		return try await withUnsafeThrowingContinuation { continuation in
			self.modifyRecordsResultBlock = { result in
				switch result {
				case .success: continuation.resume()
				case .failure(let error): continuation.resume(throwing: error)
				}
			}
			database.add(self)
		}
	}
}
