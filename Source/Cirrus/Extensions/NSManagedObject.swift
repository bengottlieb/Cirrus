//
//  NSManagedObject.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CoreData
import CloudKit

extension NSManagedObject: CKRecordSeed {
	public subscript(key: String) -> CKRecordValue? {
		self.value(forKey: key) as? CKRecordValue
	}
	
	public var recordID: CKRecord.ID? {
		if let managedObjectIDField = Cirrus.Configuration.instance.managedObjectIDField {
			guard let id = self.value(forKey: managedObjectIDField) as? String else { return nil }
			return CKRecord.ID(recordName: id)
		}
		
		return CKRecord.ID(recordName: objectID.uriRepresentation().absoluteString)
	}
	
	public var recordType: CKRecord.RecordType { entity.name! }
	public var savedFieldNames: [String] { [] }
}
