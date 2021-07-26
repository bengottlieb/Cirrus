//
//  Cirrus+Sync.swift
//  Cirrus+Sync
//
//  Created by Ben Gottlieb on 7/19/21.
//

import CloudKit
import CoreData
import Suite

extension Cirrus {
	func updateChanges(in context: NSManagedObjectContext) {
		let unsyncedObjects = context.recentlyChangedObjects.sorted { self.configuration.shouldEntity($0.entity, sortBefore: $1.entity) }
		let deletedObjects = context.recentlyDeletedObjects
		
		for object in deletedObjects {
			QueuedDeletions.instance.queue(recordID: object.recordID, in: object.database)
		}

		if unsyncedObjects.isNotEmpty {
			for object in unsyncedObjects {
				if object.isDeleted { continue }
				object.cirrusRecordStatus = .hasLocalChanges
				object.cirrus_changedKeys = []
			}
		}
		
		Cirrus.instance.configuration.synchronizer?.startSync()
	}
}
