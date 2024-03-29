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
		logg("Error: \(err.localizedDescription)")
	} catch {
		logg(error)
	}
}


@main
struct CirrusApp: App {
	@UIApplicationDelegateAdaptor(LegacyAppDelegate.self) var appDelegate
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
