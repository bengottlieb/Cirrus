//
//  NSManagedObjectContext.swift
//  NSManagedObjectContext
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

extension NSManagedObjectContext {
	var recentlyChangedObjects: [SyncedManagedObject] {
		registeredObjects.compactMap { $0 as? SyncedManagedObject }.filter { $0.cirrus_changedKeys.isNotEmpty || $0.cirrusRecordStatus.contains(.hasLocalChanges) }
	}
	
	var recentlyDeletedObjects: [SyncedManagedObject] {
		deletedObjects.compactMap { $0 as? SyncedManagedObject }
	}
	
	func clearUnsynced(_ objects: [SyncedManagedObject]) {
		objects.forEach { obj in
			obj.cirrus_changedKeys = []
		}
	}
	
	func changedRecords(named name: String) -> [SyncedManagedObject] {
		let flag = SyncedManagedObject.RecordStatusFlags.hasLocalChanges.rawValue
		return fetchAll(named: name, matching: NSPredicate(format: "(\(Cirrus.instance.configuration.statusField) & %i) == %i", flag, flag)) as? [SyncedManagedObject] ?? []
	}
}
