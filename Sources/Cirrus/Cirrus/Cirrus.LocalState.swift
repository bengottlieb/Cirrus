//
//  Cirrus.LocalState.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

extension Cirrus {
	struct LocalState: Codable {
		var lastCreatedZoneNamesList: [String] = []
		var lastSignedInUserIDName: String?
		var lastSignedInUserID: CKRecord.ID? {
			get {
				guard let name = lastSignedInUserIDName else { return nil }
				return CKRecord.ID(recordName: name)
			}
			
			set { lastSignedInUserIDName = newValue?.recordName }
		}
		
		var zoneChangeTokens: [String: Data] = [:]
	}
}

extension Cirrus {
	func changeToken(for zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
		guard let data = localState.zoneChangeTokens[zoneID.tokenIdentifier] else { return nil }
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
	}

	func changeToken(for database: CKDatabase) -> CKServerChangeToken? {
		guard let data = localState.zoneChangeTokens[database.databaseScope.tokenIdentifier] else { return nil }
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
	}

	func setChangeToken(_ token: CKServerChangeToken, for zoneID: CKRecordZone.ID) {
		localState.zoneChangeTokens[zoneID.tokenIdentifier] = token.data
	}

	func setChangeToken(_ token: CKServerChangeToken, for database: CKDatabase) {
		localState.zoneChangeTokens[database.databaseScope.tokenIdentifier] = token.data
	}
}

extension CKServerChangeToken {
	var data: Data? {
		try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
	}
}

extension CKRecordZone.ID {
	var tokenIdentifier: String { "zone_" + zoneName}
}

extension CKDatabase.Scope {
	var tokenIdentifier: String { "db_" + name }
}
