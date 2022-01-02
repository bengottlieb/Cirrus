//
//  CKRecord.ID.swift
//  CKRecord.ID
//
//  Created by Ben Gottlieb on 7/19/21.
//

import CloudKit

extension CKRecord.ID {
	func zone(in scope: CKDatabase.Scope) -> CKRecordZone? {
		Cirrus.instance.zone(withID: zoneID, in: scope)
	}
}
