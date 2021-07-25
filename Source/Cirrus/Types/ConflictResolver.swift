//
//  ConflictResolver.swift
//  ConflictResolver
//
//  Created by Ben Gottlieb on 7/17/21.
//

import CloudKit

public protocol ConflictResolver {
	func compare(local: CKRecord, remote: CKRecord) -> CKRecord
}

extension ConflictResolver {
	func resolve(error: Error, in records: [CKRecord], database db: CKDatabase) async throws -> [CKRecord]? {
		var resolvedRecords: [CKRecord] = records
		
		for err in error.allErrors {
			switch err {
			case CKError.serverRecordChanged:
				guard let remote = err.serverRecord, let index = resolvedRecords.position(of: remote) else { continue }
				
				if remote.hasSameContent(as: resolvedRecords[index]) {
					resolvedRecords.remove(at: index)
				} else {
					resolvedRecords[index] = resolve(local: resolvedRecords[index], remote: remote) ?? remote
				}

			case CKError.requestRateLimited:
				print(err)
				
			case CKError.batchRequestFailed: break
			default: return nil
			}
		}
		return resolvedRecords
	}
	
	func resolve(local: CKRecord?, remote: CKRecord?) -> CKRecord? {
		guard let local = local else { return remote }
		guard let remote = remote else { return local }
		let newRecord = compare(local: local, remote: remote)
		if newRecord == local { remote.copy(from: newRecord) }
		return remote
	}

	
}

public struct ConflictResolverLocalWins: ConflictResolver {
	public init() { }
	
	public func compare(local: CKRecord, remote: CKRecord) -> CKRecord { local }
}

public struct ConflictResolverRemoteWins: ConflictResolver {
	public init() { }
	
	public func compare(local: CKRecord, remote: CKRecord) -> CKRecord { return remote }
}

public struct ConflictResolverNewerWins: ConflictResolver {
	public init() { }
	
	public func compare(local: CKRecord, remote: CKRecord) -> CKRecord {
		if (remote.modificationDate ?? .distantFuture) > (local.modificationDate ?? .distantFuture) { return remote }
		return local
	}
}

extension Array where Element == CKRecord {
	func position(of other: CKRecord?) -> Int? {
		firstIndex { $0.recordID == other?.recordID }
	}
}
