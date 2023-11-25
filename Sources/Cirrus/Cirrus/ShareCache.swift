//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 11/25/23.
//

import Foundation
import CloudKit


extension CKShare {
	var sharedRecordName: String { record.record.id.recordName }
}

public class ShareCache {
	public static let instance = ShareCache()
	
	public static let shareRecordType = "cloudkit.share"
	
	public var cacheURL: URL? { didSet { load() }}
	
	public func permission(for recordID: CKRecord.ID) -> CKShare.ParticipantPermission? {
		guard let share = cachedShares.first(where: { $0.recordName == recordID.recordName }) else { return nil }
		
		return share.permission
	}
	
	var cachedShares: [ShareInfo] = []
	
	public func record(_ share: CKShare?) {
		guard let share else { return }
		
		if let index = cachedShares.firstIndex(where: { $0.recordName == share.sharedRecordName }) {
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
		enum CodingKeys: String, CodingKey { case url, permission, recordName }
		
		let recordName: String
		var url: URL?
		var permission: CKShare.ParticipantPermission?
		var record: CKShare?
		
		mutating func update(from share: CKShare) {
			url = share.url
			permission = share.currentUserParticipant?.permission
		}
		
		init(record: CKShare) {
			recordName = record.sharedRecordName
			url = record.url
			permission = record.currentUserParticipant?.permission
			self.record = record
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(recordName, forKey: .recordName)
			if let url { try container.encode(url, forKey: .url) }
			if let permission { try container.encode(permission.rawValue, forKey: .permission) }
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			recordName = try container.decode(String.self, forKey: .recordName)
			url = try container.decodeIfPresent(URL.self, forKey: .url)
			permission = CKShare.ParticipantPermission(rawValue: try container.decode(Int.self, forKey: .permission))
		}
	}
}
