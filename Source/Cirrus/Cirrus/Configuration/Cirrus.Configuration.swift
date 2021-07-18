//
//  Cirrus.Configuration.swift
//  Cirrus.Configuration
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Foundation
import CloudKit
import UIKit
import CoreData

extension Cirrus {
	public static func configure(with configuration: Configuration) {
		Configuration.instance = configuration
		instance.load(configuration: configuration)
	}
	
	func load(configuration config: Configuration) {
		assert(configuration == nil, "You can only configure Cirrus once.")
		configuration = config
		container = CKContainer(identifier: config.containerIdentifer)

		UIApplication.willEnterForegroundNotification.publisher()
			.sink() { _ in Task { try? await self.authenticate() }}
			.store(in: &cancelBag)
		
		Notification.Name.CKAccountChanged.publisher()
			.sink() { _ in Task { if case .authenticated = self.state { try? await self.authenticate() }}}
			.store(in: &cancelBag)
		
		Notification.Name.NSManagedObjectContextWillSave.publisher()
			.sink() { note in
				guard let context = note.object as? NSManagedObjectContext else { return }
				let unsyncedObjects = context.unsyncedObjects.sorted { self.configuration.shouldEntity($0.entity, sortBefore: $1.entity) }
				for unsynced in unsyncedObjects {
					self.configuration.entityInfo(for: unsynced.entity)?.sync(object: unsynced)
				}
			}
			.store(in: &cancelBag)
	}
	
	public struct Configuration {
		public static var instance: Configuration!
		
		public var containerIdentifer: String
		public var zoneNames: [String] = []
		
		public var managedObjectIDField: String?
		public var syncedEntityNames: [String] = []
		
		public var importer: ManagedObjectImporter?
		public var entities: [CirrusManagedObjectConfiguration]?
		
		func entityInfo(for entityDescription: NSEntityDescription?) -> CirrusManagedObjectConfiguration? {
			entities?.first { $0.entityDescription == entityDescription }
		}

		func entityInfo(for recordType: CKRecord.RecordType) -> CirrusManagedObjectConfiguration? {
			entities?.first { $0.recordType == recordType }
		}
		
		func shouldEntity(_ first: NSEntityDescription, sortBefore second: NSEntityDescription) -> Bool {
			let firstIndex = entities?.firstIndex { $0.entityName == first.name } ?? Int.max
			let secondIndex = entities?.firstIndex { $0.entityName == second.name } ?? Int.max
			
			return firstIndex <= secondIndex
		}
	}
}
