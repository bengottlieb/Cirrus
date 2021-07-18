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
	
	public var records: [CKRecord] = []
	public var errors: [Error] = []
	var isComplete = false
	
	init(query: CKQuery, in database: CKDatabase, zoneID: CKRecordZone.ID? = nil) {
		self.query = query
		self.database = database
		self.zoneID = zoneID
	}
	
	public func start() {
		run()
	}
	
	func run(cursor: CKQueryOperation.Cursor? = nil) {
		let operation = CKQueryOperation(query: query)
		operation.zoneID = zoneID
		operation.recordMatchedBlock = { recordID, result in
			switch result {
			case .success(let record): self.records.append(record)
			case .failure(let error): self.errors.append(error)
			}
		}
		
		operation.queryResultBlock = { result in
			switch result {
			case .failure(let error): self.errors.append(error)
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
				await Task.sleep(1_000)
			}
		}
		
		public typealias Element = CKRecord
		var sequence: AsyncRecordSequence
		
	}
	

	public __consuming func makeAsyncIterator() -> RecordIterator {
		RecordIterator(sequence: self)
	}
}

