//
//  SyncedContainer+SyncAll.swift
//  
//
//  Created by Ben Gottlieb on 12/22/21.
//

import Foundation
import CloudKit

public extension SyncedContainer {
	enum SyncAllError: Error { case noObjectInfo }
	func sync(all objectType: SyncedManagedObject.Type, in database: CKDatabase) async throws {
		let context = importContext
		let entity = objectType.entity()
		guard let info = await Cirrus.instance.configuration.entityInfo(for: entity) else { throw SyncAllError.noObjectInfo }
		let records = AsyncRecordSequence(recordType: info.recordType, in: database)
		print(records)
		
		for try await record in records {
			let change = CKRecordChange.changed(record.recordID, record)
			await Cirrus.instance.configuration.synchronizer?.process(downloadedChange: change)
		}
	}
}
