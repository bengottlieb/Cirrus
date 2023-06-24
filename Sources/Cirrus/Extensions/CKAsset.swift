//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/24/23.
//

import CloudKit

extension CKAsset {
	var json: [String: Any] { ["record-asset": fileURL?.absoluteString ?? ""] }
	
	convenience init?(json: [String: Any]) {
		guard let raw = json["record-asset"] as? String, let url = URL(string: raw) else { return nil }
		
		self.init(fileURL: url)
	}
}
