//
//  Cirrus+Sync.swift
//  Cirrus+Sync
//
//  Created by Ben Gottlieb on 7/19/21.
//

import CloudKit
import CoreData

extension Cirrus {
	func syncContext(_ context: NSManagedObjectContext) async throws {
		let unsyncedObjects = context.unsyncedObjects.sorted { self.configuration.shouldEntity($0.entity, sortBefore: $1.entity) }
		let deletedObjects = context.recentlyDeletedObjects
		
		for database in [container.privateCloudDatabase, container.publicCloudDatabase, container.sharedCloudDatabase] {
			let deleted = deletedObjects.filter { $0.database == database }.compactMap { $0.recordID }
			if deleted.isNotEmpty {
				try? await database.delete(recordIDs: deleted)
			}

			let records = unsyncedObjects.filter { $0.database == database }.compactMap { CKRecord($0) }
			if records.isNotEmpty {
				try await database.save(records: records)
			}
		}
		context.clearUnsynced(unsyncedObjects)
		
	}
}
