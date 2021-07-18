//
//  DataStore.swift
//  DataStore
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class DataStore {
	static let instance = DataStore()
	
	let container: NSPersistentContainer
	let viewContext: NSManagedObjectContext
	var importContext: NSManagedObjectContext
	
	init() {
		container = NSPersistentContainer(name: "Emoji")
		container.loadPersistentStores { description, error in }
		viewContext = container.viewContext
		importContext = container.newBackgroundContext()
	}
}
