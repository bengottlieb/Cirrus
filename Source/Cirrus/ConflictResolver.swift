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
				guard let remote = err.ckRecord, let index = resolvedRecords.firstIndex(where: { $0.recordID == remote.recordID }) else { return nil }
				if remote.hasSameContent(as: resolvedRecords[index]) {
					resolvedRecords.remove(at: index)
				} else {
					resolvedRecords[index] = resolve(local: resolvedRecords[index], remote: remote)
				}
			default: return nil
			}
		}
		return resolvedRecords
	}
	
	func resolve(local: CKRecord, remote: CKRecord) -> CKRecord {
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
