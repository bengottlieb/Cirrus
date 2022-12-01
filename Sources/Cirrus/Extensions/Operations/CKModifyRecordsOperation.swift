//
//  CKModifyRecordsOperation.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import CloudKit

extension CKModifyRecordsOperation {
	public func save(in database: CKDatabase, atomically: Bool = true) async throws {
		assert(recordIDsToDelete.isEmpty, "using CKModifyRecordsOperation.save() to delete records is not supported")
		
		guard let records = recordsToSave, records.isNotEmpty else { return }
		if await Cirrus.instance.mutability.isReadOnlyForCloudOps {
			print("Not saving \(records.count) records, no cloud mutability")
			return
		}
		var errors: [Error] = []
		
		self.perRecordSaveBlock = { recordID, result in
			switch result {
			case .failure(let error): errors.append(error)
			case .success: break
			}
		}
		
		self.savePolicy = .changedKeys
		self.isAtomic = atomically
		return try await withUnsafeThrowingContinuation { continuation in
			self.modifyRecordsResultBlock = { result in
				switch result {
				case .success:
					if errors.isEmpty {
						continuation.resume()
					} else {
						continuation.resume(throwing: Cirrus.MultipleErrors.build(errors: errors))
					}
				case .failure(let error): continuation.resume(throwing: error)
				}
			}
			qualityOfService = .userInitiated
			database.add(self)
		}
	}
	
	static let maxRecordsPerOperation = 400
	public func delete(from database: CKDatabase, atomically: Bool = false) async throws -> [CKRecord.ID] {
		assert(recordsToSave.isEmpty, "using CKModifyRecordsOperation.delete() to save records is not supported")
		
		guard let recordIDs = recordIDsToDelete, recordIDs.isNotEmpty else { return [] }
		
		if await Cirrus.instance.mutability.isReadOnlyForCloudOps {
			print("Not deleting record, no cloud mutability")
			return []
		}
		
		if let count = recordsToSave?.count, count >= Self.maxRecordsPerOperation {
			print("You cannot save more than \(Self.maxRecordsPerOperation) records at once")
			return []
		}
		
		var errors: [Error] = []
		var deleted: [CKRecord.ID] = []
		
		self.isAtomic = atomically
		return try await withUnsafeThrowingContinuation { continuation in
			self.perRecordDeleteBlock = { id, result in
				switch result {
				case .success: deleted.append(id)
				case .failure(let error): errors.append(error)
				}
			}
			self.modifyRecordsResultBlock = { result in
				switch result {
				case .success: break
				case .failure(let error): errors.append(error)
				}
				
				if errors.count == 0 {
					continuation.resume(returning: deleted)
				} else {
					continuation.resume(throwing: Cirrus.MultipleErrors.build(errors: errors))
				}
			}
			qualityOfService = .userInitiated
			database.add(self)
		}
	}
}
