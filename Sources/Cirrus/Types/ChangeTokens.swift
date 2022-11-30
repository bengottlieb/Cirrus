//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 11/30/22.
//

import Foundation
import CloudKit

public class ChangeTokens: Codable {
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
	
	func tokens(for zoneIDs: [CKRecordZone.ID]) -> [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration] {
		var results: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [:]
		
		for zone in zoneIDs {
			if let token = changeToken(for: zone) {
				results[zone] = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: token, resultsLimit: nil, desiredKeys: nil)
			}
		}
		return results
	}
}

