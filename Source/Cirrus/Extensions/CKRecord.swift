//
//  CKRecord.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

public protocol CKRecordSeed {
	var recordID: CKRecord.ID? { get }
	var recordType: CKRecord.RecordType { get }
	var savedFieldNames: [String] { get }
	subscript(key: String) -> CKRecordValue? { get }
}

public extension CKRecord {
	convenience init?(seed: CKRecordSeed) {
		guard let id = seed.recordID else {
			self.init(recordType: seed.recordType)
			return nil
		}

		self.init(recordType: seed.recordType, recordID: id)
		for name in seed.savedFieldNames {
			self[name] = seed[name]
		}
	}
}
