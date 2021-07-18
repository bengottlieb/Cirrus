//
//  CirrusApp.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit

@main
struct CirrusApp: App {
	let configuration = Cirrus.Configuration(containerIdentifer: "iCloud.con.standalone.cloudkittesting", zoneNames: ["Flags"])
	
	init() {
		Cirrus.configure(with: configuration)
		
		Cirrus.Notifications.userSignedIn.publisher()
			.eraseToAnyPublisher()
			.onSuccess { _ in
				Task() {
					do {
						for try await record in Cirrus.instance.container.privateCloudDatabase.records(ofType: "Flag") {
							print("Got: \(record["country"] as? String ?? "Missing country")")
						}
					} catch {
						print("Error when fetching: \(error)")
					}
				}

					
//					do {
//						try await Cirrus.instance.container.privateCloudDatabase.save(records: Flag.flags.map { CKRecord($0)! })
//					} catch let err as NSError {
//						print("Error: \(err.localizedDescription)")
//					} catch {
//						print(error)
//					}
		}
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
