//
//  CKRecordSeed.swift
//  CKRecordSeed
//
//  Created by Ben Gottlieb on 7/19/21.
//

import CloudKit

public protocol CKRecordSeed {
	var recordID: CKRecord.ID? { get }
	var recordType: CKRecord.RecordType { get }
	var savedFieldNames: [String] { get }
	var parentRelationshipName: String? { get }
	var savedRelationshipNames: [String] { get }
	subscript(key: String) -> CKRecordValue? { get }
	var recordZone: CKRecordZone? { get }
	func reference(for name: String, action: CKRecord.ReferenceAction) -> CKRecord.Reference?
	var locallyModifiedAt: Date? { get }
}
