//
//  Flag.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

struct Flag: CKRecordSeed {
	var recordID: CKRecord.ID? { CKRecord.ID(recordName: country, zoneID: Cirrus.instance.zones["Flags"]!.zoneID) }
	var recordZone: CKRecordZone? { Cirrus.instance.zone(named: "flags") }
	var parentRelationshipName: String? { nil }
	var savedRelationshipNames: [String] { [] }
	var locallyModifiedAt: Date? { nil }

	var recordType: CKRecord.RecordType { "flag" }
	
	var savedFieldNames: [String] { ["country", "emoji"] }
	
	func reference(for name: String, action: CKRecord.ReferenceAction = .none) -> CKRecord.Reference? { nil }
	subscript(key: String) -> CKRecordValue? {
		switch key {
		case "country": return country as CKRecordValue
		case "emoji": return emoji as CKRecordValue
		default: return nil
		}
	}
	
	var country: String
	var emoji: String
}

extension Flag {
	static let flags = [
		Flag(country: "USA", emoji: "🇺🇸"),
		Flag(country: "Tanzania", emoji: "🇹🇿"),
		Flag(country: "Japan", emoji: "🇯🇵"),
		Flag(country: "Afghanistan", emoji: "🇦🇫"),
		Flag(country: "Canada", emoji: "🇨🇦"),
		Flag(country: "Piratania", emoji: "🏴‍☠️"),
		Flag(country: "Switzerland", emoji: "🇨🇭"),
		
	]
}
