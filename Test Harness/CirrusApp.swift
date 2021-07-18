//
//  CirrusApp.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit


func addEmoji() async {
	do {
		let emoji = Emoji.cluser(count: 10)
		try await Cirrus.instance.container.privateCloudDatabase.save(records: emoji.map { CKRecord($0)! })
	} catch let err as NSError {
		print("Error: \(err.localizedDescription)")
	} catch {
		print(error)
	}
}


@main
struct CirrusApp: App {
	var configuration = Cirrus.Configuration(containerIdentifer: "iCloud.con.standalone.cloudkittesting", zoneNames: ["emoji"])
	let dataStore = DataStore.instance
	
	init() {
		let context = dataStore.importContext
		configuration.importer = SimpleObjectImporter(context: context)
		configuration.entities = [
			SimpleManagedObject(recordType: "emoji", entityName: "Emoji", idField: "uuid", in: context),
			SimpleManagedObject(recordType: "badge", entityName: "Badge", idField: "uuid", in: context),
			SimpleManagedObject(recordType: "emojiBadge", entityName: "EmojiBadge", idField: "uuid", parent: "emoji", pertinent: ["badge"], in: context),
		]
		
		Cirrus.configure(with: configuration)
		
		Cirrus.Notifications.userSignedIn.publisher()
			.eraseToAnyPublisher()
			.onSuccess { _ in
			//	DataStore.instance.sync()
			}
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, dataStore.viewContext)
		}
	}
}
