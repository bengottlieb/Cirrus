//
//  NSManagedObject.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CoreData
import CloudKit

struct UnresolvedReference {
	let object: NSManagedObject
	let field: String
	let reference: CKRecord.Reference
}

extension NSManagedObject {
	func load(cloudKitRecord: CKRecord) throws -> [UnresolvedReference] {
		var references: [UnresolvedReference] = []
		
		for key in cloudKitRecord.allKeys() {
			let value = cloudKitRecord[key]
			
			if let ref = value as? CKRecord.Reference {
				references.append(UnresolvedReference(object: self, field: key, reference: ref))
			} else {
				self.setValue(cloudKitRecord[key], forKey: key)
			}
		}
		
		return references
	}
}

extension NSManagedObject: CKRecordSeed {
	public subscript(key: String) -> CKRecordValue? {
		self.value(forKey: key) as? CKRecordValue
	}
	
	public var recordID: CKRecord.ID? {
		guard let info = Cirrus.instance.configuration.managedObjectInfo(for: self) else { return nil }

		guard let id = self.value(forKey: info.idField) as? String else { return nil }
		return CKRecord.ID(recordName: id)
	}
	
	public var recordType: CKRecord.RecordType { entity.name! }
	public var savedFieldNames: [String] { [] }
}
