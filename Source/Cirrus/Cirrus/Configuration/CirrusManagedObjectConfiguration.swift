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
	var recordType: CKRecord.RecordType { get }
	var entityDescription: NSEntityDescription { get }
	var parentKey: String? { get }
	var pertinentRelationships: [String] { get }

	func record(with id: CKRecord.ID, in context: NSManagedObjectContext) -> SyncedManagedObject?
	func sync(object: SyncedManagedObject)
}

extension CirrusManagedObjectConfiguration {
	public var entityName: String { entityDescription.name ?? "" }
}

public struct SimpleManagedObject: CirrusManagedObjectConfiguration {
	public let recordType: CKRecord.RecordType
	public let entityDescription: NSEntityDescription
	public let parentKey: String?
	public let pertinentRelationships: [String]
	let entityName: String
	
	public init(recordType: CKRecord.RecordType, entityName: String, parent: String? = nil, pertinent: [String] = [], in context: NSManagedObjectContext) {
		self.recordType = recordType
		self.entityName = entityName
		self.entityDescription = context.persistentStoreCoordinator!.managedObjectModel.entitiesByName[entityName]!
		self.parentKey = parent
		self.pertinentRelationships = pertinent
	}
	
	public func record(with id: CKRecord.ID, in context: NSManagedObjectContext) -> SyncedManagedObject? {
		let pred = NSPredicate(format: "\(Cirrus.instance.configuration.idField) == %@", id.recordName)
		return context.fetchAny(named: entityName, matching: pred) as? SyncedManagedObject
	}
	
	public func sync(object: SyncedManagedObject) {
		guard let record = CKRecord(object) else {
			print("Failed to create a CKRecord")
			return
		}
		
		Task() {
			do {
				try await object.database.save(record: record)
			} catch {
				print((error as NSError).userInfo)
				print("Failed to save \(record.recordType): \(error)")
			}
		}
	}
}
