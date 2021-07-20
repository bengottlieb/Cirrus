//
//  ManagedObjectSynchronizer.swift
//  ManagedObjectSynchronizer
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CoreData
import CloudKit

public protocol ManagedObjectSynchronizer {
	func process(downloadedChange change: CKRecordChange) async
	func finishImporting() async
	func startSync()
}

public class SimpleObjectSynchronizer: ManagedObjectSynchronizer {
	let context: NSManagedObjectContext
	let connector: ReferenceConnector
	
	public init(context: NSManagedObjectContext) {
		self.context = context
		self.connector = ReferenceConnector(context: context)
	}
	
	public func finishImporting() async {
		await context.perform {
			self.connector.connectUnresolved()
			self.context.saveContext(toDisk: true)
		}
	}
	
	public func startSync() {
		Task() {
			await self.uploadLocalChanges()
		}
	}
	
	public func uploadLocalChanges() async {
		let syncableEntities = await Cirrus.instance.configuration.entities ?? []
		var pending: [CKDatabase.Scope: [CKRecord]] = [:]

		await context.perform {
			for entity in syncableEntities {
				let changed = self.context.changedRecords(named: entity.entityName)
				for object in changed {
					guard let record = CKRecord(object) else { continue }
					let scope = object.database.databaseScope
					var current = pending[scope] ?? []
					current.append(record)
					pending[scope] = current
				}
			}
		}
		
		for scope in CKDatabase.Scope.allScopes {
			let deletions = await PendingDeletions.instance.allPendingDeletions(in: scope.database)
			do {
				try await scope.database.delete(recordIDs: deletions)
				await PendingDeletions.instance.clear(deleted: deletions)
			} catch {
				logg(error: error, "Failed to delete records: \(deletions)")
			}
		}
			
		for (scope, records) in pending {
			do {
				try await scope.database.save(records: records)
			} catch {
				logg(error: error, "Failed to save records: \(records)")
			}
		}
		
	}
	
	public func process(downloadedChange change: CKRecordChange) async {
		guard let info = await Cirrus.instance.configuration.entityInfo(for: change.recordType) else { return }
		
		let idField = await Cirrus.instance.configuration.idField
		do {
			switch change {
			case .changed(let id, let record):
				try await context.perform {
					if let object = info.record(with: id, in: self.context) {
						try object.load(cloudKitRecord: record, using: self.connector)
					} else {
						let object = self.context.insertEntity(named: info.entityDescription.name!) as! SyncedManagedObject
						object.setValue(id.recordName, forKey: idField)
						try object.load(cloudKitRecord: record, using: self.connector)
					}
				}
				
			case .deleted(let id, _):
				if let object = info.record(with: id, in: context) {
					context.delete(object)
				}
			}
		} catch {
			print("Failed to change: \(error)")
		}
	}
}

