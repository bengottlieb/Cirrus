//
//  DataStore.swift
//  DataStore
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData
import Suite

class DataStore: ObservableObject {
	static let instance = DataStore()
	
	let container: NSPersistentContainer
	let viewContext: NSManagedObjectContext
	var importContext: NSManagedObjectContext
	var isSyncing = false { didSet { self.objectWillChange.sendOnMain() }}
	
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
				if let context = note.object as? NSManagedObjectContext, context.persistentStoreCoordinator == self.container.persistentStoreCoordinator {
					if context != self.viewContext {
						self.viewContext.perform { self.viewContext.mergeChanges(fromContextDidSave: note) }
					}
					if context != self.importContext {
						self.importContext.perform { self.importContext.mergeChanges(fromContextDidSave: note) }
					}
				}
			}
			.store(in: &cancelBag)
	}
	
	func sync(fromBeginning: Bool = false) async throws {
		isSyncing = true
		let zoneIDs = await [Cirrus.instance.zone(named: "emoji")!.zoneID]
		do {
			for try await change in await Cirrus.instance.container.privateCloudDatabase.changes(in: zoneIDs, fromBeginning: fromBeginning) {
				
				await Cirrus.instance.configuration.synchronizer?.process(downloadedChange: change)
			}
			await Cirrus.instance.configuration.synchronizer?.finishImporting()
			isSyncing = false
		}
	}
	
	func badge(with emoji: String) -> BadgeMO {
		let predicate = NSPredicate(format: "content == %@", emoji)
		if let found: BadgeMO = viewContext.fetchAny(matching: predicate) { return found }
		
		let badge: BadgeMO = viewContext.insertObject()
		
		badge.content = emoji
		return badge
		
	}
}
