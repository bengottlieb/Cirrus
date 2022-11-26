//
//  ConflictResolver.swift
//  ConflictResolver
//
//  Created by Ben Gottlieb on 7/17/21.
//

import CloudKit

public enum CloudSyncWinner { case local, remote }

public protocol ConflictResolver {
	func compare(local: CKRecord, localModifiedAt: Date?, remote: CKRecord) -> CKRecord
}

extension ConflictResolver {
	func resolve(error: Error, in records: [CKRecordProviding], database db: CKDatabase) async throws -> [CKRecordProviding]? {
		var resolvedRecords = records
		
		for err in error.allErrors {
			switch err {
			case CKError.serverRecordChanged:
				guard let remote = err.serverRecord, let index = resolvedRecords.position(of: remote) else { continue }
				
				if remote.hasSameContent(as: resolvedRecords[index].record) {
					resolvedRecords.remove(at: index)
				} else {
					switch resolve(local: resolvedRecords[index].record, localModifiedAt: resolvedRecords[index].modifiedAt, remote: remote) {
					case .local:
						remote.copy(from: resolvedRecords[index].record)
						
					case .remote:
						break
					}
				}

			case CKError.requestRateLimited:
				print(err)
				
			case CKError.batchRequestFailed: break
			default: return nil
			}
		}
		return resolvedRecords
	}
	
	func resolve(local: CKRecord?, localModifiedAt: Date?, remote: CKRecord?) -> CloudSyncWinner {
		guard let local = local else { return .remote }
		guard let remote = remote else { return .local }
		let newRecord = compare(local: local, localModifiedAt: localModifiedAt, remote: remote)
		if newRecord == local { return .local }
		return .remote
	}

	
}

public struct ConflictResolverLocalWins: ConflictResolver {
	public init() { }
	
	public func compare(local: CKRecord, localModifiedAt: Date?, remote: CKRecord) -> CKRecord { local }
}

public struct ConflictResolverRemoteWins: ConflictResolver {
	public init() { }
	
	public func compare(local: CKRecord, localModifiedAt: Date?, remote: CKRecord) -> CKRecord { return remote }
}

public struct ConflictResolverNewerWins: ConflictResolver {
	public init() { }
	
	public func compare(local: CKRecord, localModifiedAt: Date?, remote: CKRecord) -> CKRecord {
		let remoteDate = remote.modificationDate ?? .distantFuture
		let localDate = local.modificationDate ?? localModifiedAt ?? .distantFuture
		
		if remoteDate > localDate { return remote }
		return local
	}
}

extension Array where Element == CKRecordProviding {
	func position(of other: CKRecord?) -> Int? {
		firstIndex { $0.record.recordID == other?.recordID }
	}
}
