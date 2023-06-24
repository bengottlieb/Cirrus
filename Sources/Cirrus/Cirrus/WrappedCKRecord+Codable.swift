//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/24/23.
//

import Foundation

extension WrappedCKRecord: Encodable {
	enum CodingKeys: String, CodingKey { case database, recordIDName, recordIDZoneName, recordType, isDirty, cache, recordFields }
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(recordID.recordName, forKey: .recordIDName)
		try container.encode(recordID.zoneID.zoneName, forKey: .recordIDZoneName)
	}
}

