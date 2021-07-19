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
		return CKRecord.ID(recordName: id)
	}
	
	public var recordType: CKRecord.RecordType {
		guard let info = Cirrus.instance.configuration.entityInfo(for: entity) else { return entity.name! }
		return info.recordType
	}

	public var savedFieldNames: [String] { Array(entity.attributesByName.keys) }
}
