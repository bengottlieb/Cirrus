//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/24/23.
//

import CloudKit

public struct EncodedCKRecordReference: Codable {
	enum CodingKeys: String, CodingKey { case id, action }
	let reference: CKRecord.Reference
	
	init(_ ref: CKRecord.Reference) {
		reference = ref
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let id = try container.decode(EncodedCKRecordID.self, forKey: .id)
		let action = try container.decode(UInt.self, forKey: .action)
		
		reference = CKRecord.Reference(recordID: id.id, action: CKRecord.ReferenceAction(rawValue: action) ?? .none)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(EncodedCKRecordID(reference.recordID), forKey: .id)
		try container.encode(reference.action.rawValue, forKey: .action)
		
	}
}

extension CKRecord.Reference {
	var json: [String: Any] {
		["reference": ["id": recordID.json, "action": action.rawValue]]
	}
	
	convenience init?(json: [String: Any]) {
		guard
			let info = json["reference"] as? [String: Any],
			let idFields = info["id"] as? [String: Any],
			let id = CKRecord.ID(idFields),
			let actionValue = info["action"] as? UInt,
			let action = CKRecord.ReferenceAction(rawValue: actionValue)
		else { return nil }
		
		self.init(recordID: id, action: action)
	}
}
