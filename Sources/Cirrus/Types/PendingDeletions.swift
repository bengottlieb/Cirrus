//
//  QueuedDeletions.swift
//  QueuedDeletions
//
//  Created by Ben Gottlieb on 7/19/21.
//

import CoreData
import CloudKit
import Suite

class QueuedDeletions {
	static let instance = QueuedDeletions()
	
	@FileBackedCodable(url: .cache(named: "cirrus-pending-deletions"), initialValue: []) var pending: [Deletion]
	
	func queue(recordID id: CKRecord.ID?, in database: CKDatabase) {
		guard let id = id, !pending.contains(where: { $0.recordID == id && $0.scope == database.databaseScope }) else { return }
		pending.append(Deletion(recordName: id.recordName, zoneName: id.zone(in: database.databaseScope)?.zoneID.zoneName, scope: database.databaseScope))
	}
	
	func clear(deleted: [Deletion]) {
		pending = pending.filter { pending in  !deleted.contains { $0.recordName == pending.recordName && $0.scope == pending.scope } }
	}

	struct Deletion: Codable {
		let recordName: String
		var zoneName: String?
		let scope: CKDatabase.Scope
		
		var recordID: CKRecord.ID {
			
			if let zoneName = zoneName, let zone = Cirrus.instance.privateZone(named: zoneName, in: scope) {
				return CKRecord.ID(recordName: recordName, zoneID: zone.zoneID)
			} else {
				return CKRecord.ID(recordName: recordName)
			}
		}
	}
}

extension Array where Element == QueuedDeletions.Deletion {
	func contains(recordID: CKRecord.ID?, in scope: CKDatabase.Scope) -> Bool {
		contains { $0.recordID == recordID && $0.scope == scope }
	}

	func deletions(in database: CKDatabase) -> [CKRecord.ID] {
		filter { $0.scope == database.databaseScope }.map { $0.recordID }
	}
	
}
