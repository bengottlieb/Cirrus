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
	
	init(database: CKDatabase = .public) {
		self.database = database
	}
	
	func cache(_ object: CacheObjectType) async throws {
		let id = object.ckRecordID
		
		if let record = try await database.fetchRecord(withID: id) {
			try object.write(to: record)
			try await database.save(record)
		} else {
			let record = try object.createRecord()
			try await database.save(record)
		}
	}
	
	func fetch(objectID id: String) async throws -> CacheObjectType? {
		if let record = try await database.fetchRecord(withID: CKRecord.ID(recordName: id)) {
			let object = try CacheObjectType(record)
			return object
		}
		return nil
	}
}
