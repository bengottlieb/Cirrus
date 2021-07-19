//
//  CKRecord.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

public extension CKRecord {
	convenience init?(_ seed: CKRecordSeed) {
		guard let id = seed.recordID else {
			self.init(recordType: seed.recordType)
			return nil
		}

		self.init(recordType: seed.recordType, recordID: id)
		for name in seed.savedFieldNames {
			self[name] = seed[name]
		}
		
		if let parentKey = seed.parentRelationshipName, let parent = seed.reference(for: parentKey, action: .none) {
			self.parent = parent
		}
		
		for key in seed.savedRelationshipNames {
			if let reference = seed.reference(for: key, action: .none) {
				self[key] = reference
			}
		}
	}
	
	func copy(from record: CKRecord) {
		for field in self.allKeys() {
			if record[field] == nil { self[field] = nil }
		}
		for field in record.allKeys() {
			self[field] = record[field]
		}
	}
	
	func hasSameContent(as record: CKRecord) -> Bool {
		let keys = self.allKeys()
		if keys != record.allKeys() { return false }
		
		for key in keys {
			if !areEqual(self[key], record[key]) { return false }
		}
		return true
	}
}
