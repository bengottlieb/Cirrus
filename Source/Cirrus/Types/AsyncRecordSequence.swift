//
//  AsyncRecordSequence.swift
//  AsyncRecordSequence
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

public class AsyncRecordSequence: AsyncSequence {
	public typealias AsyncIterator = RecordIterator
	public typealias Element = CKRecord

	let query: CKQuery
	let database: CKDatabase
	let zoneID: CKRecordZone.ID?
	var resultChunkSize: Int = 0
	
	public var records: [CKRecord] = []
	public var errors: [Error] = []
	var isComplete = false
	var desiredKeys: [String]?

	init(recordType: CKRecord.RecordType, desiredKeys: [String]? = nil, predicate: NSPredicate? = nil, in database: CKDatabase, zoneID: CKRecordZone.ID? = nil) {
		self.query = CKQuery(recordType: recordType, predicate: predicate ?? .init(value: true))
		self.database = database
		self.zoneID = zoneID
		self.desiredKeys = desiredKeys
	}
	
	init(query: CKQuery, desiredKeys: [String]? = nil, in database: CKDatabase, zoneID: CKRecordZone.ID? = nil) {
		self.query = query
		self.database = database
		self.zoneID = zoneID
		self.desiredKeys = desiredKeys
	}
	
	public func start() {
		run()
	}
	
	func run(cursor: CKQueryOperation.Cursor? = nil) {
		let operation: CKQueryOperation
		
		if let cursor = cursor {
			operation = CKQueryOperation(cursor: cursor)
		} else {
			operation = CKQueryOperation(query: query)
		}
		
		operation.desiredKeys = desiredKeys
		operation.zoneID = zoneID
		operation.resultsLimit = resultChunkSize
		operation.recordMatchedBlock = { recordID, result in
			switch result {
			case .failure(let error):
				Cirrus.instance.handleReceivedError(error)
				self.errors.append(error)
			case .success(let record): self.records.append(record)
			}
		}
		
		operation.queryResultBlock = { result in
			switch result {
			case .failure(let error):
				Cirrus.instance.handleReceivedError(error)
				self.errors.append(error)
			case .success(let possibleCursor):
				if let cursor = possibleCursor {
					self.run(cursor: cursor)
				} else {
					self.isComplete = true
				}
			}
		}
		
		database.add(operation)
	}

	public struct RecordIterator: AsyncIteratorProtocol {
		var position = 0
		public mutating func next() async throws -> CKRecord? {
			while true {
				if let error = sequence.errors.first { throw error }
				if position < sequence.records.count {
					position += 1
					return sequence.records[position - 1]
				}
				
				if sequence.isComplete { return nil }
				try? await Task.sleep(nanoseconds: 1_000)
			}
		}
		
		public typealias Element = CKRecord
		var sequence: AsyncRecordSequence
		
	}
	
	public __consuming func makeAsyncIterator() -> RecordIterator {
		self.start()
		return RecordIterator(sequence: self)
	}
}

