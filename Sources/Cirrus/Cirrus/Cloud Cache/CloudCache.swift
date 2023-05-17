//
//  CloudCache.swift
//  
//
//  Created by Ben Gottlieb on 5/16/23.
//

import Foundation
import CloudKit

public class CloudCache<CacheObjectType: CKRecordConvertable> {
	let database: CKDatabase
	
	public init(database: CKDatabase = .public) {
		self.database = database
	}
	
	public func store(_ object: CacheObjectType) async throws {
		let id = object.ckRecordID
		if await !Cirrus.instance.state.isSignedIn { return }
		
		if let record = try await database.fetchRecord(withID: id) {
			try object.write(to: record)
			try await database.save(record)
		} else {
			let record = try object.createRecord()
			try await database.save(record)
		}
	}
	
	public func fetch(objectID id: String) async throws -> CacheObjectType? {
		if let record = try await database.fetchRecord(withID: CKRecord.ID(recordName: id)) {
			let object = try CacheObjectType(record)
			return object
		}
		return nil
	}
	
	public func fetch(objectsMatching predicate: NSPredicate) async throws -> [CacheObjectType] {
		let records = try await database.fetchRecords(ofType: CacheObjectType.recordType, matching: predicate)
		
		return try records.map { record in try CacheObjectType(record) }
	}
}
