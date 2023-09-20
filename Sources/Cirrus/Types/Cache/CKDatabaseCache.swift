//
//  CKDatabaseCache.swift
//
//
//  Created by Ben Gottlieb on 6/24/23.
//

import CloudKit

public class CKDatabaseCache: ObservableObject {
	let scope: CKDatabase.Scope
	let container: CKContainerCache
	let url: URL
	var isPullingChanges = false
	
	public var records: [CKRecord.ID: WrappedCKRecord] = [:]
	
	init(scope: CKDatabase.Scope, in container: CKContainerCache) {
		self.scope = scope
		self.container = container
		self.url = container.url.appendingPathComponent(scope.name, conformingTo: .directory)
		try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
		load()
	}
	
	public func allRecords<Record: WrappedCKRecord>() -> [Record] {
		Array(records.values.filter { $0.recordType == Record.recordType }) as! [Record]
	}
	
	public func uncache(_ id: CKRecord.ID?) {
		guard let id, let wrapped = self[id] else { return }
		
		let url = url(for: wrapped)
		try? FileManager.default.removeItem(at: url)
		records.removeValue(forKey: id)
	}
	
	public func resolve<Record: WrappedCKRecord>(reference: CKRecord.Reference?) -> Record? {
		guard let reference else { return nil }
		
		return records[reference.recordID] as? Record
	}
	
	public func create<Record: WrappedCKRecord>(recordWithID id: CKRecord.ID) async throws -> Record? {
		if let record = records[id] as? Record { return record }
		do {
			guard let ckRecord = try await scope.database.fetchRecord(withID: id) else { return nil }

			let recordClass = container.translator(ckRecord.recordType) ?? WrappedCKRecord.self
			let newRecord = recordClass.init(record: ckRecord, in: scope.database)
			records[id] = newRecord
			return newRecord as? Record
		} catch {
			return nil
		}
	}
	
	public subscript(id: CKRecord.ID) -> WrappedCKRecord? {
		get { records[id] }
		set {
			guard let newValue else {
				records.removeValue(forKey: id)
				return
			}
			
			records[id] = newValue
			save(record: newValue)
		}
	}
	
	public func cache(record: WrappedCKRecord) {
		self.records[record.recordID] = record
		save(record: record)
	}
	
	public func load(records: [CKRecord]) {
		for record in records {
			if let current = self.records[record.recordID] {
				current.merge(fromLatest: record)
				save(record: current)
				container.delegate?.didUpdateRemoteRecord(record: current, in: scope)
			} else {
				if record.recordType == CKRecord.cloudShareRecordType { continue }					 // don't worry about cloudkit shares
				let type = container.translator(record.recordType) ?? WrappedCKRecord.self
				
				let newRecord = type.init(record: record, in: scope.database)
				self.records[record.recordID] = newRecord
				save(record: newRecord)
				container.delegate?.didAddRemoteRecord(record: newRecord, in: scope)
			}
		}
	}
	
	func url(for record: WrappedCKRecord) -> URL {
		let typeURL = url.appendingPathComponent(record.recordType, conformingTo: .directory)
		try? FileManager.default.createDirectory(at: typeURL, withIntermediateDirectories: true)
		return typeURL.appendingPathComponent(record.recordID.recordName, conformingTo: .json)
	}
	
	func save(record: WrappedCKRecord) {
		do {
			records[record.recordID] = record
			let recordURL = url(for: record)
			let data = try JSONEncoder().encode(record)
			try data.write(to: recordURL)
		} catch {
			cirrus_log("Failed to save \(record): \(error)")
		}
	}
	
	func save() {
		for record in records.values {
			save(record: record)
		}
	}
	
	func load() {
		do {
			let recordTypeURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
			
			for recordTypeURL in recordTypeURLs {
				let recordType = recordTypeURL.lastPathComponent
				let recordClass = container.translator(recordType) ?? WrappedCKRecord.self
				if let fileURLs = try? FileManager.default.contentsOfDirectory(at: recordTypeURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
					for fileURL in fileURLs {
						if let data = try? Data(contentsOf: fileURL) {
							let record = try JSONDecoder().decode(recordClass, from: data)
							self.records[record.recordID] = record
						}
					}
				}
			}
		} catch {
			cirrus_log("Failed to load cached database \(scope.name): \(error)")
		}
	}
}
