//
//  SyncedManagedObject.swift
//  SyncedManagedObject
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData
import CloudKit

extension SyncedManagedObject {
	public struct RecordStatusFlags: OptionSet {
		public let rawValue: Int32

		public init(rawValue: Int32) { self.rawValue = rawValue }
		public static let hasLocalChanges    = RecordStatusFlags(rawValue: 1 << 0)

	}
}

open class SyncedManagedObject: NSManagedObject, CKRecordSeed {
	var isLoadingFromCloud = 0
	var cirruschangedKeys: Set<String> = []
	
	var cirrusRecordStatus: RecordStatusFlags {
		get { RecordStatusFlags(rawValue: self.value(forKey: Cirrus.instance.configuration.statusField) as? Int32 ?? 0) }
		set {
			self.setValue(newValue.rawValue, forKey: Cirrus.instance.configuration.statusField)
		}
	}
	
	open override func didChangeValue(forKey key: String) {
		if isLoadingFromCloud == 0, !cirruschangedKeys.contains(key), key != Cirrus.instance.configuration.idField, key != Cirrus.instance.configuration.statusField, key != Cirrus.instance.configuration.modifiedAtField {
			cirruschangedKeys.insert(key)
			self.setValue(Date(), forKey: Cirrus.instance.configuration.modifiedAtField)
		}
		super.didChangeValue(forKey: key)
	}
	
	open override func awakeFromInsert() {
		super.awakeFromInsert()
		self.setValue(UUID().uuidString, forKey: Cirrus.instance.configuration.idField)
	}
	
	open var database: CKDatabase { Cirrus.instance.container.privateCloudDatabase }
	open var recordZone: CKRecordZone? { Cirrus.instance.defaultRecordZone }

	open var parentRelationshipName: String? { Cirrus.instance.configuration.entityInfo(for: entity)?.parentKey }
	open var savedRelationshipNames: [String] { Cirrus.instance.configuration.entityInfo(for: entity)?.pertinentRelationships ?? [] }
}

extension SyncedManagedObject {
	func load(cloudKitRecord: CKRecord, using connector: ReferenceConnector) throws {
		isLoadingFromCloud += 1
		let statusFieldKey = Cirrus.instance.configuration.statusField
		let modifiedAtKey = Cirrus.instance.configuration.modifiedAtField
		
		self.setValue(cloudKitRecord.recordID.recordName, forKey: Cirrus.instance.configuration.idField)
		for key in cloudKitRecord.allKeys() {
			if key == statusFieldKey || key == modifiedAtKey { continue }
			let value = cloudKitRecord[key]
			
			if let ref = value as? CKRecord.Reference {
				connector.connect(reference: ref, to: self, key: key)
			} else {
				self.setValue(cloudKitRecord[key], forKey: key)
			}
		}
		
		if let parent = cloudKitRecord.parent, let parentKey = Cirrus.instance.configuration.entityInfo(for: entity)?.parentKey {
			connector.connect(reference: parent, to: self, key: parentKey)
		}
		
		self.cirrusRecordStatus = []
		isLoadingFromCloud -= 1
	}
}

extension SyncedManagedObject {
	public subscript(key: String) -> CKRecordValue? {
		self.value(forKey: key) as? CKRecordValue
	}
	
	public var recordID: CKRecord.ID? {
		guard let id = self.value(forKey: Cirrus.instance.configuration.idField) as? String else { return nil }
		if let zone = self.recordZone { return CKRecord.ID(recordName: id, zoneID: zone.zoneID) }
		return CKRecord.ID(recordName: id)
	}
	
	public var recordType: CKRecord.RecordType {
		guard let info = Cirrus.instance.configuration.entityInfo(for: entity) else { return entity.name! }
		return info.recordType
	}

	public var savedFieldNames: [String] { Array(entity.attributesByName.keys) }
	public func reference(for name: String, action: CKRecord.ReferenceAction = .none) -> CKRecord.Reference? {
		guard
				let relationship = entity.relationshipsByName[name],
				!relationship.isToMany,
				let target = value(forKey: name) as? SyncedManagedObject,
				let recordID = target.recordID else { return nil }
		
		return CKRecord.Reference(recordID: recordID, action: action)
	}

}
