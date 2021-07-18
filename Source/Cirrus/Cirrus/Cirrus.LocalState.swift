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
		var lastSignedInUserID: String?
		
		var zoneChangeTokens: [String: Data] = [:]
	}
}

extension Cirrus.LocalState {
	func changeToken(for zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
		guard let data = zoneChangeTokens[zoneID.zoneName] else { return nil }
		return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
	}

	mutating func setChangeToken(_ token: CKServerChangeToken, for zoneID: CKRecordZone.ID) {
		zoneChangeTokens[zoneID.zoneName] = token.data
	}
}

extension CKServerChangeToken {
	var data: Data? {
		try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
	}
}
