//
//  Cirrus.LocalState.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

public class ZoneChangeTokens: Codable {
	public var tokens: [String: Data] = [:]
	
	public init(saved: [String: Data]? = nil) {
		tokens = saved ?? [:]
	}
	
	func changeToken(for zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
		guard let data = tokens[zoneID.tokenIdentifier] else { return nil }
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
	}

	func changeToken(for database: CKDatabase) -> CKServerChangeToken? {
		guard let data = tokens[database.databaseScope.tokenIdentifier] else { return nil }
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
	}

	func setChangeToken(_ token: CKServerChangeToken, for zoneID: CKRecordZone.ID) {
		tokens[zoneID.tokenIdentifier] = token.data
	}

	func setChangeToken(_ token: CKServerChangeToken, for database: CKDatabase) {
		tokens[database.databaseScope.tokenIdentifier] = token.data
	}
	
	func clear() { tokens = [:] }
}

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
		
		var zoneChangeTokens = ZoneChangeTokens()
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
