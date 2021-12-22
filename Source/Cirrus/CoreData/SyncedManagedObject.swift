//
//  SyncedManagedObject.swift
//  SyncedManagedObject
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData
import CloudKit
import Suite

extension SyncedManagedObject {
	public struct RecordStatusFlags: OptionSet {
		public let rawValue: Int32

		public init(rawValue: Int32) { self.rawValue = rawValue }
		public static let hasLocalChanges    = RecordStatusFlags(rawValue: 1 << 0)

	}
}

open class SyncedManagedObject: NSManagedObject, CKRecordSeed, Identifiable {
	var isLoadingFromCloud = 0
	var cirrus_changedKeys: Set<String> = []
	open var id: String { self.value(forKey: Cirrus.instance.configuration.idField) as? String ?? "" }

    public func deleteFromCloudKit() async throws {
        guard let id = recordID else { return }
        _ = try await database.delete(recordID: id)
    }

	public var locallyModifiedAt: Date? { self.value(forKey: Cirrus.instance.configuration.modifiedAtField) as? Date }
	var cirrusRecordStatus: RecordStatusFlags {
		get { RecordStatusFlags(rawValue: self.value(forKey: Cirrus.instance.configuration.statusField) as? Int32 ?? 0) }
		set {
			self.setValue(newValue.rawValue, forKey: Cirrus.instance.configuration.statusField)
		}
	}
	
	open override func didChangeValue(forKey key: String) {
		if isLoadingFromCloud == 0, !cirrus_changedKeys.contains(key), key != Cirrus.instance.configuration.idField, key != Cirrus.instance.configuration.statusField, key != Cirrus.instance.configuration.modifiedAtField {
			cirrus_changedKeys.insert(key)
			self.setValue(Date(), forKey: Cirrus.instance.configuration.modifiedAtField)
		}
		super.didChangeValue(forKey: key)
	}
	
	open override func awakeFromInsert() {
		super.awakeFromInsert()
		self.setValue(UUID().uuidString, forKey: Cirrus.instance.configuration.idField)
	}
	
    open var database: CKDatabase { .private }
	open var recordZone: CKRecordZone? { Cirrus.instance.defaultRecordZone }

	open var parentRelationshipName: String? { Cirrus.instance.configuration.entityInfo(for: entity)?.parentKey }
	open var savedRelationshipNames: [String] { Cirrus.instance.configuration.entityInfo(for: entity)?.pertinentRelationships ?? [] }
}

extension SyncedManagedObject {
	public func reloadFromCloud() async throws {
		if let id = recordID, let record = try await database.fetchRecord(withID: id) {
			try load(cloudKitRecord: record, using: nil)
		}
	}

	func load(cloudKitRecord: CKRecord, using connector: ReferenceConnector?) throws {
		isLoadingFromCloud += 1
		let statusFieldKey = Cirrus.instance.configuration.statusField
		let modifiedAtKey = Cirrus.instance.configuration.modifiedAtField
		
		self.setValue(cloudKitRecord.modificationDate, forKey: modifiedAtKey)
		self.setValue(cloudKitRecord.recordID.recordName, forKey: Cirrus.instance.configuration.idField)
		for key in cloudKitRecord.allKeys() {
			if key == statusFieldKey || key == modifiedAtKey { continue }
			let value = cloudKitRecord[key]
			
			if let ref = value as? CKRecord.Reference {
				connector?.connect(reference: ref, to: self, key: key)
			} else if let asset = value as? CKAsset {
				do {
					if let url = asset.fileURL {
						let data = try Data(contentsOf: url)
						self.setValue(data, forKey: key)
					}
				}
			} else if self.entity.attributesByName[key] != nil {
				self.setValue(cloudKitRecord[key], forKey: key)
			}
		}
		
		if let parent = cloudKitRecord.parent, let parentKey = Cirrus.instance.configuration.entityInfo(for: entity)?.parentKey {
			connector?.connect(reference: parent, to: self, key: parentKey)
		}
		
		self.cirrusRecordStatus = []
		isLoadingFromCloud -= 1
	}
}

extension SyncedManagedObject {
	public subscript(key: String) -> CKRecordValue? {
		let attributes = self.entity.attributesByName[key]
		
		if attributes?.allowsExternalBinaryDataStorage == true {
			if let data = self.value(forKey: key) as? Data {
				let url = fileURL(for: key)
				do {
					try data.write(to: url)
					return CKAsset(fileURL: url)
				} catch {
					logg(error: error, "Failed to write external data blob out")
				}
			}
			return nil
		}
		return self.value(forKey: key) as? CKRecordValue
	}

	func fileURL(for key: String) -> URL {
		let name = "\(objectID.uriRepresentation().absoluteString)_\(key).dat"
		return URL.tempFile(named: name)
	}
	
	public var recordID: CKRecord.ID? {
		guard let id = self.value(forKey: Cirrus.instance.configuration.idField) as? String else { return nil }
		if self.database == .public { return CKRecord.ID(recordName: id) }
		if let zone = self.recordZone { return CKRecord.ID(recordName: id, zoneID: zone.zoneID) }
		return CKRecord.ID(recordName: id)
	}
	
	public var recordType: CKRecord.RecordType {
		guard let info = Cirrus.instance.configuration.entityInfo(for: entity) else { return entity.name! }
		return info.recordType
	}

	public var savedFieldNames: [String] { Array(entity.attributesByName.keys).removing([Cirrus.instance.configuration.idField, Cirrus.instance.configuration.statusField, Cirrus.instance.configuration.modifiedAtField]) }
	public func reference(for name: String, action: CKRecord.ReferenceAction = .none) -> CKRecord.Reference? {
		guard
				let relationship = entity.relationshipsByName[name],
				!relationship.isToMany,
				let target = value(forKey: name) as? SyncedManagedObject,
				let recordID = target.recordID else { return nil }
		
		return CKRecord.Reference(recordID: recordID, action: action)
	}

}
