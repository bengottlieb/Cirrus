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
	func updateChanges(in context: NSManagedObjectContext) async throws {
		let unsyncedObjects = context.recentlyChangedObjects.sorted { self.configuration.shouldEntity($0.entity, sortBefore: $1.entity) }
		let deletedObjects = context.recentlyDeletedObjects
		
		for object in deletedObjects {
			PendingDeletions.instance.queue(recordID: object.recordID, in: object.database)
		}

		if unsyncedObjects.isNotEmpty {
			for object in unsyncedObjects {
				object.cirrusRecordStatus = .hasLocalChanges
				object.cirruschangedKeys = []
			}
			do {
				try context.save()
			} catch {
				logg(error: error, "Failed to save context after clearing changed keys")
			}
		}
		
		Cirrus.instance.configuration.synchronizer?.startSync()
	}
}
