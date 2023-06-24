//
//  CKRecord+JSON.swift
//
//
//  Created by Ben Gottlieb on 6/24/23.
//

import CloudKit

extension Dictionary where Key == String {
	var jsonSafe: [String: Any?] {
		var safe: [String: Any?] = [:]
		
		for key in keys {
			guard let value = self[key] else { continue }
			
			if let ref = value as? CKRecord.Reference {
				safe[key] = ref.json
			} else if let asset = value as? CKAsset {
				safe[key] = asset.json
			} else {
				safe[key] = value
			}
		}

		return safe
	}
	
	var cloudKitValues: [String: CKRecordValue?] {
		var results: [String: CKRecordValue?] = [:]
		for (key, value) in self {
			if let dict = value as? [String: Any] {
				if let ref = CKRecord.Reference(json: dict) {
					results[key] = ref
				} else if let asset = CKAsset(json: dict) {
					results[key] = asset
				}
			} else if let ckValue = value as? CKRecordValue {
				results[key] = ckValue
			}
		}
		return results
	}
}

extension CKRecord {
	var jsonDictionary: [String: Any?] {
		set {
			for (key, value) in newValue.cloudKitValues {
				self[key] = value
			}
		}
		
		get {
			var dict: [String: Any] = [:]
			
			for key in allKeys() {
				guard let value = self[key] else { continue }
				dict[key] = value
			}
			
			return dict.jsonSafe
		}
	}
}

