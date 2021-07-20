//
//  NSManagedObjectContext.swift
//  NSManagedObjectContext
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

extension NSManagedObjectContext {
	var recentlyChangedObjects: [SyncedManagedObject] {
		registeredObjects.compactMap { $0 as? SyncedManagedObject }.filter { $0.cirruschangedKeys.isNotEmpty }
	}
	
	var recentlyDeletedObjects: [SyncedManagedObject] {
		deletedObjects.compactMap { $0 as? SyncedManagedObject }
	}
	
	func clearUnsynced(_ objects: [SyncedManagedObject]) {
		objects.forEach { obj in
			obj.cirruschangedKeys = []
		}
	}
	
	func changedRecords(named name: String) -> [SyncedManagedObject] {
		fetchAll(named: name, matching: NSPredicate(format: "\(Cirrus.instance.configuration.statusField) != 0")) as? [SyncedManagedObject] ?? []
	}
}
