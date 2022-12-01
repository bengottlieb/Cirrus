//
//  AsyncZoneChangesSequence.swift
//  AsyncZoneChangesSequence
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CloudKit

public enum CKRecordChange {
	case deleted(CKRecord.ID, CKRecord.RecordType)
	case changed(CKRecord.ID, CKRecord)
	case badRecord

	var recordType: CKRecord.RecordType? {
		switch self {
		case .deleted(_, let type): return type
		case .changed(_, let record): return record.recordType
		case .badRecord: return nil
		}
	}
}

public actor AsyncZoneChangesSequence: AsyncSequence {
	public typealias AsyncIterator = RecordIterator
	public typealias Element = CKRecordChange
		
	let database: CKDatabase
	let zoneIDs: [CKRecordZone.ID]
	var resultChunkSize: Int = 0
	var tokens: ChangeTokens
	var isRunning = false
	
	public var changes: [CKRecordChange] = []
	public var errors: [Error] = []
	var isComplete = false
	var queryType: CKDatabase.RecordChangesQueryType
	
	init(zoneIDs: [CKRecordZone.ID], in database: CKDatabase, queryType: CKDatabase.RecordChangesQueryType = .recent, tokens: ChangeTokens) {
		self.database = database
		self.zoneIDs = zoneIDs
		self.queryType = queryType
		self.tokens = tokens

		if queryType == .all {
			tokens.clear()
		}
	}
	
	private func startFetch() async throws -> Bool {
		if isRunning { return true }
		if await !Cirrus.instance.state.isSignedIn || database == .public || zoneIDs.isEmpty { return false }

		isRunning = true
		
		let _: Void = try await withCheckedThrowingContinuation { continuation in
			let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: self.zoneIDs, configurationsByRecordZoneID: self.tokens.tokens(for: self.zoneIDs))
			operation.qualityOfService = .userInitiated
			
			if queryType != .createdOnly {
				operation.recordWithIDWasDeletedBlock = { id, type in
					if type.isEmpty {
						self.changes.append(.badRecord)
					} else {
						self.changes.append(CKRecordChange.deleted(id, "\(type)"))
					}
				}
			}
			
			operation.recordWasChangedBlock = { id, result in
				switch result {
				case .failure(let error):
					Task { await Cirrus.instance.shouldCancelAfterError(error) }
					self.errors.append(error)
					
				case .success(let record):
					self.changes.append(.changed(id, record))
				}
			}
			
			operation.recordZoneFetchResultBlock = { zoneID, results in
				switch results {
				case .failure(let error):
					Task { await Cirrus.instance.shouldCancelAfterError(error) }
					self.errors.append(error)
					
				case .success(let (serverToken, clientToken, moreComing)):		// (serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool)
					self.tokens.setChangeToken(serverToken, for: zoneID)
					print("more coming: \(moreComing), Zone change token: \(serverToken), client token: \(String(describing: clientToken))")
					if !moreComing { self.isComplete = true }
				}
			}
			
			operation.fetchRecordZoneChangesResultBlock = { result in
				switch result {
				case .failure(let error):
					Task { await Cirrus.instance.shouldCancelAfterError(error) }
					self.errors.append(error)
					continuation.resume(throwing: error)

				case .success:
					self.isComplete = true
					continuation.resume()
				}
			}
			
			database.add(operation)
		}
		return true
	}

	public struct RecordIterator: AsyncIteratorProtocol {
		var position = 0
		public mutating func next() async throws -> CKRecordChange? {
			if await !sequence.isRunning { if try await !sequence.startFetch() { return nil } }
			
			while true {
				if let error = await sequence.errors.first { throw error }
				let changes = await sequence.changes
				
				if position < changes.count {
					position += 1
					return changes[position - 1]
				}
				
				if await sequence.isComplete {
					return nil
				}
	//			_ = try await sequence.run()
			}
		}
		
		public typealias Element = CKRecordChange
		var sequence: AsyncZoneChangesSequence
		
	}
	
	nonisolated public __consuming func makeAsyncIterator() -> RecordIterator {
		RecordIterator(sequence: self)
	}
}

