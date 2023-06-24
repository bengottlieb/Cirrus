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
	
	
	var json: [String: Any] { ["record-id": [recordName, zoneID.zoneName, zoneID.ownerName]] }
	
	convenience init?(_ json: [String: Any]) {
		guard let fields = json["record-id"] as? [String], fields.count == 3 else { return nil }
		
		self.init(recordName: fields[0], zoneID: CKRecordZone.ID(zoneName: fields[1], ownerName: fields[2]))
	}
}

public struct EncodedCKRecordID: Codable {
	enum CodingKeys: String, CodingKey { case name, zone, owner }
	let id: CKRecord.ID
	
	init(_ id: CKRecord.ID) {
		self.id = id
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id.recordName, forKey: .name)
		try container.encode(id.zoneID.zoneName, forKey: .zone)
		try container.encode(id.zoneID.ownerName, forKey: .owner)
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let name = try container.decode(String.self, forKey: .name)
		let zoneName = try container.decode(String.self, forKey: .zone)
		let owner = try container.decode(String.self, forKey: .owner)
		id = CKRecord.ID(recordName: name, zoneID: CKRecordZone.ID(zoneName: zoneName, ownerName: owner))
	}
}

