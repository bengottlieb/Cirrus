//
//  Cirrus_macOSApp.swift
//  Cirrus_macOS
//
//  Created by Ben Gottlieb on 8/5/21.
//

import SwiftUI
import Suite
import CloudKit

@main
struct Cirrus_macOSApp: App {
	@NSApplicationDelegateAdaptor(LegacyAppDelegate.self) var appDelegate
	var configuration = Cirrus.Configuration(identifier: "iCloud.con.standalone.cloudkittesting", zones: ["emoji"])
	
	init() {
		SyncedContainer.setup(name: "Emoji")
		let context = SyncedContainer.instance.importContext
		configuration.idField = "uuid"
		configuration.synchronizer = SimpleObjectSynchronizer(context: context)
		configuration.entities = [
			SimpleManagedObject(recordType: "emoji", entityName: "Emoji", in: context),
			SimpleManagedObject(recordType: "badge", entityName: "Badge", in: context),
			SimpleManagedObject(recordType: "emojiBadge", entityName: "EmojiBadge", parent: "emoji", pertinent: ["badge"], in: context),
		]
		
		Cirrus.configure(with: configuration)
		Logger.instance.level = .verbose
		Task() {
			await Cirrus.instance.container.privateCloudDatabase.setupSubscriptions([.init()])
		}
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, SyncedContainer.instance.viewContext)
		}
	}
}
