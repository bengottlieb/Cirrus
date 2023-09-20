//
//  WrappedCKRecord.swift
//
//
//  Created by Ben Gottlieb on 6/19/23.
//

import CloudKit
import SwiftUI


open class WrappedCKRecord: ObservableObject, Identifiable, Equatable {
	open class var recordType: CKRecord.RecordType { "" }
	public var record: CKRecord? { didSet { recordChanged() }}
	public var database: CKDatabase
	public var recordID: CKRecord.ID
	public var recordType: CKRecord.RecordType
	public var isDirty = false
	public var isSaving = false
	public var cache: [String: CKRecordValue?] = [:]
	public var id: String { recordID.recordName }
	
	
	required public init(record: CKRecord, in database: CKDatabase = .private) {
		self.record = record
		self.database = database
		recordID = record.recordID
		recordType = record.recordType
		didLoad(record: record)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		recordID = try container.decode(EncodedCKRecordID.self, forKey: .recordID).id
		database = try container.decode(CKDatabase.Scope.self, forKey: .database).database
		recordType = try container.decode(CKRecord.RecordType.self, forKey: .recordType)
		
		let dict = try container.decode([String: Any].self, forKey: .recordFields)
		if !dict.isEmpty {
			record = CKRecord(recordType: recordType, recordID: recordID)
			record?.jsonDictionary = dict
		}
		cache = try container.decode([String: Any?].self, forKey: .cache).cloudKitValues
		
		if let parent = try container.decodeIfPresent(EncodedCKRecordReference.self, forKey: .recordParent) {
			record?.parent = parent.reference
		}
	}
	
	open func merge(fromLatest latest: CKRecord) {
		record = latest
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
		try await load()
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
	
	open func asyncSave(fetchingFirst: Bool = false) {
		Task {
			do {
				if fetchingFirst {
					try? await performFetch()
				}
				try await save()
			} catch {
				cirrus_log("Failed to save record: \(error)")
			}
		}
	}
	
	open func willSave(to record: CKRecord) async throws { }		// move any fields to save into the record
	
	open func didLoad(record: CKRecord) { }			// move any data out of the record
	
	public func save() async throws {
		record = record ?? CKRecord(recordType: recordType, recordID: recordID)
		try await willSave(to: record!)
		try await performSave(record: record!, firstTime: true)
		CKContainerCache.instance?[database.databaseScope].save(record: self)
	}
	
	func performSave(record: CKRecord, firstTime: Bool) async throws {
		if !isDirty { return }
		
		if isSaving, firstTime { return }
		isSaving = true
		for (key, value) in cache {
			record[key] = value
		}
		
		do {
			try await database.save(record)
			cache = [:]
			isDirty = false
		} catch let error as CKError {
			cirrus_log("Error saving record: \(recordID): \(error.localizedDescription)")
			switch error.code {
			case .serverRecordChanged:
				if firstTime {
					try? await Task.sleep(nanoseconds: 1_000_000_000)
					try await performFetch()
					try await willSave(to: record)
					try await performSave(record: record, firstTime: false)
				} else {
					cirrus_log("Error re-fetching record: \(error.localizedDescription)")
					throw error
				}
			default:
				throw error
			}
		}
		isSaving = false
	}
	
	func load() async throws {
		try await performFetch()
		if let record { didLoad(record: record) }
	}
	
	open func performFetch() async throws {
		if let newRecord = try? await database.record(for: recordID) {
			merge(fromLatest: newRecord)
		}
	}
	
	func recordChanged() {
		guard let record else { return }
		recordID = record.recordID
		recordType = record.recordType
	}
}
