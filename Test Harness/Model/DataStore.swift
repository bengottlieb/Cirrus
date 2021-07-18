//
//  DataStore.swift
//  DataStore
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData
import Suite

class DataStore {
	static let instance = DataStore()
	
	let container: NSPersistentContainer
	let viewContext: NSManagedObjectContext
	var importContext: NSManagedObjectContext
	
	var cancelBag: Set<AnyCancellable> = []
	
	func entity(named name: String) -> NSEntityDescription {
		container.persistentStoreCoordinator.managedObjectModel.entitiesByName[name]!
	}
	
	init() {
		container = NSPersistentContainer(name: "Emoji")
		container.loadPersistentStores { description, error in }
		viewContext = container.viewContext
		importContext = container.newBackgroundContext()
		
		Notification.Name.NSManagedObjectContextDidSave.publisher()
			.sink { note in
				if let context = note.object as? NSManagedObjectContext, context.persistentStoreCoordinator == self.container.persistentStoreCoordinator, context != self.viewContext {
					self.viewContext.perform {
						self.viewContext.mergeChanges(fromContextDidSave: note)
					}
				}
			}
			.store(in: &cancelBag)
	}
	
	func sync() {
		Task() {
			let zoneIDs = await [Cirrus.instance.zone(named: "emoji")!.zoneID]
			do {
				for try await change in await Cirrus.instance.container.privateCloudDatabase.changes(in: zoneIDs) {
					
					await Cirrus.instance.configuration.importer?.process(change: change)
				}
				await Cirrus.instance.configuration.importer?.finishImporting()
			}
		}
	}
}
