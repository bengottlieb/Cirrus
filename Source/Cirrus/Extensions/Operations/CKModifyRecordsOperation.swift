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
		var errors: [Error] = []
		
		self.perRecordSaveBlock = { recordID, result in
			switch result {
			case .failure(let error): errors.append(error)
			case .success: break
			}
		}
		
		self.isAtomic = atomically
		return try await withUnsafeThrowingContinuation { continuation in
			self.modifyRecordsResultBlock = { result in
				switch result {
				case .success:
					if errors.isEmpty {
						continuation.resume()
					} else if errors.count == 1 {
						continuation.resume(throwing: errors[0])
					} else {
						continuation.resume(throwing: Cirrus.MultipleErrors(errors: errors))
					}
				case .failure(let error): continuation.resume(throwing: error)
				}
			}
			database.add(self)
		}
	}
	
	public func delete(from database: CKDatabase) async throws {
		assert(recordsToSave.isEmpty, "using CKModifyRecordsOperation.delete() to save records is not supported")

		guard let recordIDs = recordIDsToDelete, recordIDs.isNotEmpty else { return }
		
		var errors: [Error] = []
		
		return try await withUnsafeThrowingContinuation { continuation in
			self.perRecordDeleteBlock = { id, result in
				switch result {
				case .success: break
				case .failure(let error): errors.append(error)
				}
			}
			self.modifyRecordsResultBlock = { result in
				switch result {
				case .success: break
				case .failure(let error): errors.append(error)
				}
				
				if errors.count == 0 {
					continuation.resume()
				} else if errors.count == 1 {
					continuation.resume(throwing: errors[0])
				} else {
					continuation.resume(throwing: Cirrus.MultipleErrors(errors: errors))
				}
			}
			database.add(self)
		}
	}
}
