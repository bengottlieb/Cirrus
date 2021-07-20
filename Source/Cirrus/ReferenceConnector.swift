//
//  ReferenceConnector.swift
//  ReferenceConnector
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CloudKit
import CoreData

struct UnresolvedReference {
	let object: SyncedManagedObject
	let key: String
	let reference: CKRecord.Reference
}

public class ReferenceConnector {
	let context: NSManagedObjectContext
	var unresolved: [UnresolvedReference] = []
	
	init(context: NSManagedObjectContext) {
		self.context = context
	}
	
	public func connect(reference: CKRecord.Reference, to target: SyncedManagedObject, key: String) {
		if !resolve(reference: reference, to: target, key: key) {
			unresolved.append(UnresolvedReference(object: target, key: key, reference: reference))
		}
	}
	
	func connectUnresolved() {
		for item in unresolved {
			resolve(reference: item.reference, to: item.object, key: item.key)
		}
	}
	
	@discardableResult func resolve(reference: CKRecord.Reference, to target: SyncedManagedObject, key: String) -> Bool {
		guard
			let relationship = target.entity.relationshipsByName[key],
			let info = Cirrus.instance.configuration.entityInfo(for: relationship.destinationEntity)
		else { return false }
		
		if let connected = info.record(with: reference.recordID, in: context) {
			target.isLoadingFromCloud += 1
			if relationship.isToMany {
				let current = target.value(forKey: key) as? NSMutableSet ?? NSMutableSet()
				current.add(connected)
				current.setValue(current, forKey: key)
			} else {
				target.setValue(connected, forKey: key)
			}
			target.isLoadingFromCloud -= 1
			return true
		}
		return false
	}
}
