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
	
	init() {
		let context = DataStore.instance.importContext
		configuration.importer = SimpleObjectImporter(context: context)
		configuration.entities = [
			"emoji": SimpleManagedObject(entityName: "Emoji", idField: "uuid", in: context),
			"badge": SimpleManagedObject(entityName: "Badge", idField: "uuid", in: context),
			"emojiBadge": SimpleManagedObject(entityName: "EmojiBadge", idField: "uuid", in: context),
		]
		
		Cirrus.configure(with: configuration)
		
		Cirrus.Notifications.userSignedIn.publisher()
			.eraseToAnyPublisher()
			.onSuccess { _ in
				Task() {
					let zoneIDs = [Cirrus.instance.zone(named: "emoji")!.zoneID]
					do {
						for try await change in
								Cirrus.instance.container.privateCloudDatabase.changes(in: zoneIDs) {
							
							Cirrus.instance.configuration.importer?.process(change: change)
						}
						Cirrus.instance.configuration.importer?.finishImporting()
						
//						try await Cirrus.instance.container.privateCloudDatabase.delete(record: CKRecord(Flag.flags[0]))
//					} catch {
//						print("Error when fetching: \(error)")
//					}
					
						//await addEmoji()
					}
				}
			}
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
