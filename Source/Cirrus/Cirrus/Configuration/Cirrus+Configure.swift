//
//  Cirrus+Configure.swift
//  Cirrus+Configure
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CloudKit
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
}
