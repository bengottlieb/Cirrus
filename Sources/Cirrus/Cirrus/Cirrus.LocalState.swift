//
//  Cirrus.LocalState.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

extension Cirrus {
	struct LocalState: Codable, Equatable {
		var lastCreatedZoneNamesList: [String] = []
		var lastSignedInUserIDName: String?
		var lastSignedInUserID: CKRecord.ID? {
			get {
				guard let name = lastSignedInUserIDName else { return nil }
				return CKRecord.ID(recordName: name)
			}
			
			set { lastSignedInUserIDName = newValue?.recordName }
		}
		
		var changeTokens = ChangeTokens()
	}
}

public extension CKServerChangeToken {
	var data: Data? {
		try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
	}
}

public extension CKRecordZone.ID {
	var tokenIdentifier: String { "zone_" + zoneName}
}

public extension CKDatabase.Scope {
	var tokenIdentifier: String { "db_" + name }
}
