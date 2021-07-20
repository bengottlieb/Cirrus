//
//  NSManagedObjectContext.swift
//  NSManagedObjectContext
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

extension NSManagedObjectContext {
	var unsyncedObjects: [SyncedManagedObject] {
		registeredObjects.compactMap { $0 as? SyncedManagedObject }.filter { $0.changedKeys.isNotEmpty }
	}
	
	var recentlyDeletedObjects: [SyncedManagedObject] {
		deletedObjects.compactMap { $0 as? SyncedManagedObject }
	}
	
	func clearUnsynced(_ objects: [SyncedManagedObject]) {
		objects.forEach { obj in
			obj.changedKeys = []
		}
	}
}
