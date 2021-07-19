//
//  SyncedManagedObject.swift
//  SyncedManagedObject
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData
import CloudKit

open class SyncedManagedObject: NSManagedObject {
	var isLoadingFromCloud = false
	var changedKeys: Set<String> = []
	
	open override func didChangeValue(forKey key: String) {
		if !isLoadingFromCloud, !changedKeys.contains(key) {
			changedKeys.insert(key)
		}
		super.didChangeValue(forKey: key)
	}
	
	open var database: CKDatabase { Cirrus.instance.container.privateCloudDatabase }
	open var recordZone: CKRecordZone? { Cirrus.instance.defaultRecordZone }

	open var parentRelationshipName: String? { Cirrus.instance.configuration.entityInfo(for: entity)?.parentKey }
	open var savedRelationshipNames: [String] { Cirrus.instance.configuration.entityInfo(for: entity)?.pertinentRelationships ?? [] }
}

extension SyncedManagedObject {
	func load(cloudKitRecord: CKRecord, using connector: ReferenceConnector) throws {
		isLoadingFromCloud = true
		for key in cloudKitRecord.allKeys() {
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
		
		isLoadingFromCloud = false
	}
}

extension SyncedManagedObject: CKRecordSeed {
	public subscript(key: String) -> CKRecordValue? {
		self.value(forKey: key) as? CKRecordValue
	}
	
	public var recordID: CKRecord.ID? {
		guard let info = Cirrus.instance.configuration.entityInfo(for: entity) else { return nil }

		guard let id = self.value(forKey: info.idField) as? String else { return nil }
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
