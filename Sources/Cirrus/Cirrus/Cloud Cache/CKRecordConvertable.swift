//
//  CKRecordConvertable.swift
//  
//
//  Created by Ben Gottlieb on 5/16/23.
//

import Foundation
import CloudKit
import Suite

public protocol CKRecordConvertable: Identifiable {
	init(_ record: CKRecord) throws
	func write(to record: CKRecord) throws
	func createRecord() throws -> CKRecord
	static var recordType: CKRecord.RecordType { get }
	var ckRecordID: CKRecord.ID { get }
}

public extension Decodable where Self: CKRecordConvertable {
	init(_ record: CKRecord, using decoder: JSONDecoder = .default) throws {
		var dict: [String: Any] = [:]
		
		for (key, value) in record {
			dict[key] = value
		}
		
		let data = try JSONSerialization.data(withJSONObject: dict)
		self = try decoder.decode(Self.self, from: data)
	}
}

public extension Encodable where Self: CKRecordConvertable {
	func write(to record: CKRecord, using encoder: JSONEncoder = .default) throws {
		let json = try self.asJSON(using: encoder)
		
		for (key, value) in json {
			if let ckValue = value as? CKRecordValue {
				record[key] = ckValue
			}
		}
	}
	
	func createRecord() throws -> CKRecord {
		let record = CKRecord(recordType: Self.recordType, recordID: ckRecordID)
		try write(to: record)
		return record
	}
	
	static var recordType: CKRecord.RecordType {
		"\(Self.self)"
	}
	
	var ckRecordID: CKRecord.ID {
		CKRecord.ID(recordName: "\(self.id)")
	}
}
