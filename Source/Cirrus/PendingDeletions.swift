//
//  PendingDeletions.swift
//  PendingDeletions
//
//  Created by Ben Gottlieb on 7/19/21.
//

import CoreData
import CloudKit
import Suite

class PendingDeletions {
	static let instance = PendingDeletions()
	
	@FileBackedCodable(url: .cache(named: "cirrus-pending-deletions"), initialValue: []) var pending: [Deletion]
	
	func queue(recordID id: CKRecord.ID, in database: CKDatabase) {
		pending.append(Deletion(recordName: id.recordName, zoneName: id.zone?.zoneID.zoneName, scope: database.databaseScope))
	}
	
	func allPendingDeletions(in database: CKDatabase) -> [CKRecord.ID] {
		pending.filter { $0.scope == database.databaseScope }.map { $0.recordID }
	}
	
	struct Deletion: Codable {
		let recordName: String
		let zoneName: String?
		let scope: CKDatabase.Scope
		
		var recordID: CKRecord.ID {
			if let zoneName = zoneName, let zone = Cirrus.instance.zone(named: zoneName) {
				return CKRecord.ID(recordName: recordName, zoneID: zone.zoneID)
			} else {
				return CKRecord.ID(recordName: recordName)
			}
		}
	}
}

