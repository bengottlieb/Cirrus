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
	
	func modifiedSincePredicate(for date: Date?) -> NSPredicate {
		guard let date else { return NSPredicate(value: true) }
		return NSPredicate(format: "modificationDate < %@", date as NSDate)
	}

	func fetchAllRecords(kind: CKRecord.RecordType, modifiedSince: Date? = nil, in zoneID: CKRecordZone.ID? = nil) async throws -> [CKRecord] {
		let query = CKQuery(recordType: kind, predicate: modifiedSincePredicate(for: modifiedSince))
		
		return try await fetchAllRecords(query: query, in: zoneID)
	}

	func fetchAllRecords(query: CKQuery, in zoneID: CKRecordZone.ID? = nil) async throws -> [CKRecord] {
		let op = CKQueryOperation(query: query)
		op.zoneID = zoneID
		return try await fetchAllRecords(query: op)
	}

	func fetchAllRecords(query: CKQueryOperation) async throws -> [CKRecord] {
		var totalRecords: [CKRecord] = []
		
		var op = query
		
		while true {
			let results: ([CKRecord], CKQueryOperation.Cursor?) = try await withCheckedThrowingContinuation { continuation in
				var records: [CKRecord] = []
				
				op.recordMatchedBlock = { id, result in
					switch result {
					case .success(let record): records.append(record)
					case .failure(let error):
						cirrus_log("Failed to fetch record: \(error)")
					}
				}
				
				op.queryResultBlock = { result in
					switch result {
					case .success(let cursor):
						continuation.resume(returning: (records, cursor))
						
					case .failure(let error):
						cirrus_log("Failed to finish fetching records: \(error)")
						if records.isEmpty {
							continuation.resume(throwing: error)
						} else {
							continuation.resume(returning: (records, nil))
						}
					}
				}
				
				self.add(op)
			}
			
			totalRecords += results.0
			if let cursor = results.1 {
				op = CKQueryOperation(cursor: cursor)
			} else {
				break
			}
		}
		
		return totalRecords
	}

	func fetchRecords(withIDs ids: [CKRecord.ID], logFailures: Bool = true) async throws -> [CKRecord] {
		if ids.count > Self.maxRecordsPerFetchOperation {
			let chunks = ids.breakIntoChunks(ofSize: Self.maxRecordsPerFetchOperation)
			var results: [CKRecord] = []
			
			for chunk in chunks {
				results += try await fetchRecords(withIDs: chunk)
			}
			return results
		}

		let records: [CKRecord] = try await withCheckedThrowingContinuation { continuation in
			
			var results: [CKRecord] = []
			
			let op = CKFetchRecordsOperation(recordIDs: ids)
			op.perRecordResultBlock = { id, result in // ((_ recordID: CKRecord.ID, _ recordResult: Result<CKRecord, Error>) -> Void)?
			
				switch result {
				case .success(let record):
					results.append(record)
					
				case .failure(let error):
					if logFailures, error.cloudKitErrorCode != .unknownItem { cirrus_log("Record failed: \(id): \(error)") }
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
