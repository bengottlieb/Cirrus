//
//  CKDatabase.swift
//  
//
//  Created by Ben Gottlieb on 11/22/22.
//

import Foundation
import CloudKit


public extension CKDatabase {
	static let maxRecordsPerFetchOperation = 400

	func fetchRecords(withIDs ids: [CKRecord.ID]) async throws -> [CKRecord] {
		
		if ids.count > CKDatabase.maxRecordsPerFetchOperation {
			print("You cannot fetch more than \(Self.maxRecordsPerFetchOperation) records at once")
			return []
		}

		let records: [CKRecord] = try await withCheckedThrowingContinuation { continuation in
			
			var results: [CKRecord] = []
			
			let op = CKFetchRecordsOperation(recordIDs: ids)
			op.perRecordResultBlock = { id, result in // ((_ recordID: CKRecord.ID, _ recordResult: Result<CKRecord, Error>) -> Void)?
			
				switch result {
				case .success(let record):
					results.append(record)
					
				case .failure(let error):
					print("Record failed: \(id): \(error)")
				}
			}
			
			op.fetchRecordsResultBlock = { result in
				switch result {
				case .success:
					continuation.resume(returning: results)
					
				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
			
			add(op)
		}
		
		return records
	}
}
