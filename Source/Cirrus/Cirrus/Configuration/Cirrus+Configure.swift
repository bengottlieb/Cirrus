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
		if Reachability.instance.isOffline { state = .offline }

		UIApplication.willEnterForegroundNotification.publisher()
			.sink() { _ in Task { try? await self.authenticate() }}
			.store(in: &cancelBag)
		
		Notification.Name.CKAccountChanged.publisher()
			.sink() { _ in Task { if case .authenticated = self.state { try? await self.authenticate() }}}
			.store(in: &cancelBag)
		
		Notification.Name.NSManagedObjectContextWillSave.publisher()
			.sink() { note in
				guard let context = note.object as? NSManagedObjectContext else { return }
				context.performAndWait {
					self.updateChanges(in: context)
				}
			}
			.store(in: &cancelBag)
		
		Reachability.instance.objectWillChange
			.sink { _ in
				if Reachability.instance.isOffline {
					if self.state != .offline { self.state = .offline }
				} else if self.state == .offline {
					Task { try? await self.authenticate(evenIfOffline: true) }
				}
			}
			.store(in: &cancelBag)
	}
}
