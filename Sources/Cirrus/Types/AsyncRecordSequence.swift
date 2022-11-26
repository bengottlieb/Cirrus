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
	var checkForDuplicates = true
	
	public var records: [CKRecord] = []
	public var errors: [Error] = []
	var isComplete = false
	var desiredKeys: [String]?
	var isRunning = false
	var cursor: CKQueryOperation.Cursor?

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
	
	public var all: [CKRecord] {
		get async throws {
			for try await _ in self { }
			return records
		}
	}

	func run(cursor: CKQueryOperation.Cursor? = nil) async throws -> Bool {
		if isRunning && cursor == nil { return true }
		if await !Cirrus.instance.state.isSignedIn, database != .public { return false }
		
		isRunning = true
		var errors: [Error] = []

		let _: Void = await withUnsafeContinuation { continuation in
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
					errors.append(error)
					
				case .success(let record):
					if self.checkForDuplicates, let index = self.records.firstIndex(where: { $0.recordID == recordID }) {
						print("Received duplicate record at \(index): \(record)")
						return
					}
					self.records.append(record)
				}
			}
			
			operation.queryResultBlock = { result in
				switch result {
				case .failure(let error):
					errors.append(error)
					continuation.resume(returning: Void())
				case .success(let possibleCursor):
					self.cursor = possibleCursor
					self.isComplete = possibleCursor == nil
					continuation.resume(returning: Void())
				}
			}
			
			database.add(operation)
		}
		
		if let error = errors.first {
			await Cirrus.instance.shouldCancelAfterError(error)
		}
		
		return true
	}

	public struct RecordIterator: AsyncIteratorProtocol {
		var position = 0
		public mutating func next() async throws -> CKRecord? {
			if !sequence.isRunning {
				if try await !sequence.run() { return nil }
			}
			while true {
				if let error = sequence.errors.first { throw error }
				if position < sequence.records.count {
					position += 1
					return sequence.records[position - 1]
				}
				
				if sequence.isComplete { return nil }
				_ = try await sequence.run(cursor: sequence.cursor)
			}
		}
		
		public typealias Element = CKRecord
		var sequence: AsyncRecordSequence
		
	}
	
	public __consuming func makeAsyncIterator() -> RecordIterator {
		return RecordIterator(sequence: self)
	}
}

