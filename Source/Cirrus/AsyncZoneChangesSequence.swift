//
//  AsyncZoneChangesSequence.swift
//  AsyncZoneChangesSequence
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CloudKit

public class AsyncZoneChangesSequence: AsyncSequence {
	public typealias AsyncIterator = RecordIterator
	public typealias Element = RecordChange

	public enum RecordChange { case deleted(CKRecord.ID, CKRecord.RecordType), changed(CKRecord.ID, CKRecord) }
		
	let database: CKDatabase
	let zoneIDs: [CKRecordZone.ID]
	var resultChunkSize: Int = 0
	
	public var changes: [RecordChange] = []
	public var errors: [Error] = []
	var isComplete = false
	
	init(zoneIDs: [CKRecordZone.ID], in database: CKDatabase) {
		self.database = database
		self.zoneIDs = zoneIDs
	}
	
	public func start() {
		run()
	}
	
	var configuration: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration] {
		var results: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [:]
		
		for zone in zoneIDs {
			if let token = Cirrus.instance.localState.changeToken(for: zone) {
				results[zone] = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: token, resultsLimit: nil, desiredKeys: nil)
			}
		}
		
		return results
	}
	
	func run(cursor: CKQueryOperation.Cursor? = nil) {
		let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, configurationsByRecordZoneID: configuration)
		
		operation.recordWithIDWasDeletedBlock = { id, type in
			self.changes.append(RecordChange.deleted(id, type))
		}
		
		operation.recordWasChangedBlock = { id, result in
			switch result {
			case .failure(let error):
				Cirrus.instance.handleReceivedError(error)
				self.errors.append(error)
				
			case .success(let record):
				self.changes.append(.changed(id, record))
			}
		}
		
		operation.recordZoneFetchResultBlock = { zoneID, results in
			switch results {
			case .failure(let error):
				Cirrus.instance.handleReceivedError(error)
				self.errors.append(error)
				
			case .success(let done):		// (serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool)
				Cirrus.instance.localState.setChangeToken(done.serverChangeToken, for: zoneID)
				if !done.moreComing { self.isComplete = true }
			}
		}
		
		database.add(operation)
	}

	public struct RecordIterator: AsyncIteratorProtocol {
		var position = 0
		public mutating func next() async throws -> AsyncZoneChangesSequence.RecordChange? {
			while true {
				if let error = sequence.errors.first { throw error }
				if position < sequence.changes.count {
					position += 1
					return sequence.changes[position - 1]
				}
				
				if sequence.isComplete { return nil }
				await Task.sleep(1_000)
			}
		}
		
		public typealias Element = AsyncZoneChangesSequence.RecordChange
		var sequence: AsyncZoneChangesSequence
		
	}
	

	public __consuming func makeAsyncIterator() -> RecordIterator {
		RecordIterator(sequence: self)
	}
}

