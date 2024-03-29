//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/19/23.
//

import CloudKit

public extension CKSubscription.SubscriptionType {
	var title: String {
		switch self {
		case .query: return "query"
		case .recordZone: return "recordZone"
		case .database: return "database"
		@unknown default: return "unknown"
		}
	}
}

public extension CKSubscription {
	var detailedDescription: String {
		var result = subscriptionType.title
		if let db = self as? CKDatabaseSubscription {
			if let recordType = db.recordType { result += ": \(recordType)" }
		}
		
		return result
	}

}
