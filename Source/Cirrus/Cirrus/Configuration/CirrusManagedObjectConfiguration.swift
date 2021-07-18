//
//  ManagedObjectConfiguration.swift
//  ManagedObjectConfiguration
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CoreData
import CloudKit

public protocol CirrusManagedObjectConfiguration {
	var entityDescription: NSEntityDescription { get }
	var idField: String { get }
	
	func record(with id: CKRecord.ID, in context: NSManagedObjectContext) -> NSManagedObject?
	func sync(object: NSManagedObject)
}

public struct SimpleManagedObject: CirrusManagedObjectConfiguration {
	public let entityDescription: NSEntityDescription
	public let idField: String
	let entityName: String
	
	init(entityName: String, idField: String, in context: NSManagedObjectContext) {
		self.idField = idField
		self.entityName = entityName
		self.entityDescription = context.persistentStoreCoordinator!.managedObjectModel.entitiesByName[entityName]!
	}
	
	public func record(with id: CKRecord.ID, in context: NSManagedObjectContext) -> NSManagedObject? {
		let pred = NSPredicate(format: "\(idField) == %@", id.recordName)
		return context.fetchAny(named: entityName, matching: pred)
	}
	
	public func sync(object: NSManagedObject) {
		
	}
}
