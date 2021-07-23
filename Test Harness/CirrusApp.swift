//
//  CirrusApp.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit
import SwiftUI


func addEmoji() async {
	do {
		let emoji = Emoji.cluster(count: 10)
		try await Cirrus.instance.container.privateCloudDatabase.save(records: emoji.map { CKRecord($0)! })
	} catch let err as NSError {
		print("Error: \(err.localizedDescription)")
	} catch {
		print(error)
	}
}


@main
struct CirrusApp: App {
	@UIApplicationDelegateAdaptor(LegacyAppDelegate.self) var appDelegate
	var configuration = Cirrus.Configuration(containerIdentifer: "iCloud.con.standalone.cloudkittesting", zoneNames: ["emoji"], defaultZoneName: "emoji")
	let dataStore = DataStore.instance
	
	init() {
		let context = dataStore.importContext
		configuration.idField = "uuid"
		configuration.synchronizer = SimpleObjectSynchronizer(context: context)
		configuration.entities = [
			SimpleManagedObject(recordType: "emoji", entityName: "Emoji", in: context),
			SimpleManagedObject(recordType: "badge", entityName: "Badge", in: context),
			SimpleManagedObject(recordType: "emojiBadge", entityName: "EmojiBadge", parent: "emoji", pertinent: ["badge"], in: context),
		]
		
		Cirrus.configure(with: configuration)
		Task() {
			await Cirrus.instance.container.privateCloudDatabase.setupSubscriptions([.init()])
		}
		
		Cirrus.Notifications.userSignedIn.publisher()
			.eraseToAnyPublisher()
			.onSuccess { _ in
				Task() { try? await DataStore.instance.sync() }
			}
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, dataStore.viewContext)
		}
	}
}
