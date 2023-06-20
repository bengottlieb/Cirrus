//
//  WrappedCKRecord.swift
//
//
//  Created by Ben Gottlieb on 6/19/23.
//

import CloudKit
import SwiftUI


open class WrappedCKRecord: ObservableObject, Identifiable, Equatable {
	public var record: CKRecord? { didSet { recordChanged() }}
	public var database: CKDatabase
	public var recordID: CKRecord.ID
	public var recordType: CKRecord.RecordType
	public var isDirty = false
	public var isSaving = false
	public var cache: [String: CKRecordValue?] = [:]
	public var id: String { recordID.recordName }
	
	public init(record: CKRecord, in database: CKDatabase = .private) {
		self.record = record
		self.database = database
		recordID = record.recordID
		recordType = record.recordType
	}
	
	public static func ==(lhs: WrappedCKRecord, rhs: WrappedCKRecord) -> Bool {
		if let record = lhs.record ?? rhs.record {
			for key in record.allKeys() {
				if !areEqual(lhs[key], rhs[key]) { return false }
			}
		}
		
		return lhs.recordID == rhs.recordID
	}
		
	public init(recordID: CKRecord.ID, recordType: CKRecord.RecordType, database: CKDatabase = .private) async throws {
		self.database = database
		self.recordID = recordID
		self.recordType = recordType
		try await performFetch()
	}
	
	public subscript(key: String) -> CKRecordValue? {
		get {
			if let value = cache[key] { return value }
			return record?[key]
		}
		set {
			if isSaving { return }
			if areEqual(self[key], newValue) { return }
			if self[key] == nil, areEqual(record?[key], newValue) { return }
			
			isDirty = true
			cache[key] = newValue
		}
	}
	
	open func willSave() async throws { }		// move any fields to save into the record
	
	open func didLoad() { }			// move any data out of the record
	
	public func save() async throws {
		try await willSave()
		try await performSave(firstTime: true)
	}
	
	func performSave(firstTime: Bool) async throws {
		if !isDirty { return }
		let record = record ?? CKRecord(recordType: recordType, recordID: recordID)
		
		if isSaving { return }
		isSaving = true
		for (key, value) in cache {
			record[key] = value
		}
		
		do {
			try await database.save(record)
			cache = [:]
			isDirty = false
		} catch let error as CKError {
			switch error.code {
			case .serverRecordChanged:
				if firstTime {
					try await performFetch()
					try await willSave()
					try await performSave(firstTime: false)
				} else {
					throw error
				}
			default:
				throw error
			}
		}
	}
	
	func load() async throws {
		try await performFetch()
		didLoad()
	}
	
	func performFetch() async throws {
		record = try await CKDatabase.private.record(for: recordID)
	}
	
	func recordChanged() {
		guard let record else { return }
		recordID = record.recordID
		recordType = record.recordType
	}
}
