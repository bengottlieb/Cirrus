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
	var url: URL?
	
	public init(saved: [String: Data]? = nil) {
		tokens = saved ?? [:]
	}
	
	public static func tokens(at url: URL) -> ChangeTokens {
		let tokens = (try? ChangeTokens.loadJSON(file: url)) ?? ChangeTokens()
		tokens.url = url
		return tokens
	}
	
	func save() {
		if let url {
			try? self.saveJSON(to: url)
		}
	}
	
	public func changeToken(for zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
		guard let data = tokens[zoneID.tokenIdentifier] else { return nil }
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
	}
	
	public func changeToken(for database: CKDatabase) -> CKServerChangeToken? {
		guard let data = tokens[database.databaseScope.tokenIdentifier] else { return nil }
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
	}
	
	public func setChangeToken(_ token: CKServerChangeToken, for zoneID: CKRecordZone.ID) {
		tokens[zoneID.tokenIdentifier] = token.data
		save()
	}
	
	public func setChangeToken(_ token: CKServerChangeToken, for database: CKDatabase) {
		tokens[database.databaseScope.tokenIdentifier] = token.data
		save()
	}
	
	public func clear() {
		tokens = [:]
		save()
	}
	
	public var isEmpty: Bool { tokens.isEmpty }
	
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

