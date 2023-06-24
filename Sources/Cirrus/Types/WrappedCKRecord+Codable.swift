//
//  WrappedCKRecord+Codable.swift
//
//
//  Created by Ben Gottlieb on 6/24/23.
//

import Foundation
import CloudKit

extension WrappedCKRecord: Codable {
	enum CodingKeys: String, CodingKey { case database, recordID, recordIDZoneName, recordType, isDirty, cache, recordFields, recordParent }
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(EncodedCKRecordID(recordID), forKey: .recordID)
		try container.encode(database.databaseScope, forKey: .database)
		try container.encode(recordType, forKey: .recordType)
		
		if let record {
			try container.encode(record.jsonDictionary, forKey: .recordFields)
			if let parent = record.parent {
				try container.encode(EncodedCKRecordReference(parent), forKey: .recordParent)
			}
		} else {
			try container.encode([:], forKey: .recordFields)
		}
		
		try container.encode(cache, forKey: .cache)
		try container.encode(isDirty, forKey: .isDirty)
	}
}

