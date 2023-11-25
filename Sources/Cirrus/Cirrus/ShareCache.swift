//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 11/25/23.
//

import Foundation
import CloudKit


extension CKShare {
    var sharedRecordName: String? { nil }
    var sharedZoneName: String? { recordID.zoneID.zoneName }
}

public class ShareCache {
	public static let instance = ShareCache()
	
	public static let shareRecordType = "cloudkit.share"
	
	public var cacheURL: URL? { didSet { load() }}
	
	var cachedShares: [ShareInfo] = []

    public func permission(forRecordID recordID: CKRecord.ID) -> CKShare.ParticipantPermission? {
        guard let share = cachedShares.first(where: { $0.recordName == recordID.recordName }) else { return nil }
        
        return share.permission
    }

    public func permission(forZoneName recordZone: String) -> CKShare.ParticipantPermission? {
        guard let share = cachedShares.first(where: { $0.zoneName == recordZone }) else { return nil }
        
        return share.permission
    }

	public func record(_ share: CKShare?) {
		guard let share else { return }
		
        if let sharedName = share.sharedRecordName, let index = cachedShares.firstIndex(where: { $0.recordName == sharedName }) {
            cachedShares[index].update(from: share)
        } else if let zoneName = share.sharedZoneName, let index = cachedShares.firstIndex(where: { $0.zoneName == zoneName }) {
            cachedShares[index].update(from: share)
        } else {
			cachedShares.append(.init(record: share))
		}
		
		save()
	}
	
	func save() {
		guard let cacheURL, let data = try? JSONEncoder().encode(cachedShares) else { return }
		try? FileManager.default.removeItem(at: cacheURL)
		try? data.write(to: cacheURL)
	}
	
	func load() {
		guard let cacheURL, let data = try? Data(contentsOf: cacheURL) else { return }
		if let shares = try? JSONDecoder().decode([ShareInfo].self, from: data) {
			cachedShares = shares
		}
	}
}

extension ShareCache {
	struct ShareInfo: Codable {
		enum CodingKeys: String, CodingKey { case url, permission, recordName, zoneName }
		
		let recordName: String?
		var url: URL?
		var permission: CKShare.ParticipantPermission?
		var record: CKShare?
        var zoneName: String?
		
		mutating func update(from share: CKShare) {
			url = share.url
			permission = share.currentUserParticipant?.permission
		}
		
		init(record: CKShare) {
			recordName = record.sharedRecordName
            zoneName = record.id.zoneID.zoneName
			url = record.url
			permission = record.currentUserParticipant?.permission
			self.record = record
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
            if let recordName { try container.encode(recordName, forKey: .recordName) }
            if let zoneName { try container.encode(zoneName, forKey: .zoneName) }
			if let url { try container.encode(url, forKey: .url) }
			if let permission { try container.encode(permission.rawValue, forKey: .permission) }
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
            recordName = try container.decodeIfPresent(String.self, forKey: .recordName)
            zoneName = try container.decodeIfPresent(String.self, forKey: .zoneName)
			url = try container.decodeIfPresent(URL.self, forKey: .url)
			permission = CKShare.ParticipantPermission(rawValue: try container.decode(Int.self, forKey: .permission))
		}
	}
}
