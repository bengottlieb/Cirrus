//
//  Cirrus+Configure.swift
//  Cirrus+Configure
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CloudKit
import CoreData

#if canImport(UIKit)
import UIKit
#endif

extension Cirrus {
	public static func configure(with configuration: Configuration) {
		Configuration.instance = configuration
		instance.load(configuration: configuration)
	}
	
	func load(configuration config: Configuration) {
		assert(configuration == nil, "You can only configure Cirrus once.")
		configuration = config
		container = CKContainer(identifier: config.containerIdentifer)
		if Reachability.instance.isOffline, let userID = localState.lastSignedInUserID { state = .offline(userID) }
		
#if canImport(UIKit)
		UIApplication.willEnterForegroundNotification.publisher()
			.sink() { _ in Task { try? await self.authenticate() }}
			.store(in: &cancelBag)
#endif
		
		Notification.Name.CKAccountChanged.publisher()
			.sink() { _ in Task {
				switch self.state {
				case .authenticated, .temporaryUnavailable:
					try? await self.authenticate()
					
				default: break
				}
			}}
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
					if case .authenticated(let userID) = self.state { self.state = .offline(userID) }
				} else if self.state.isOffline {
					Task { try? await self.authenticate(evenIfOffline: true) }
				}
			}
			.store(in: &cancelBag)
		
		Task {
			do {
				try await self.authenticate()
			} catch {
				print("Error signing in: \(error)")
			}
		}
	}
}
