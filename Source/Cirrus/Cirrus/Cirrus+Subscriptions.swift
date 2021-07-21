//
//  Cirrus+Subscriptions.swift
//  Cirrus+Subscriptions
//
//  Created by Ben Gottlieb on 7/20/21.
//

import CloudKit


extension Cirrus {
	public struct SubscriptionInfo {
		var recordName: String?
		var zone: CKRecordZone?
		var predicate: NSPredicate?
		var options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
		
		func id(in scope: CKDatabase.Scope) -> CKSubscription.ID {
			if scope == .shared { return "shared-subscription" }
			if let name = recordName {
				return "\(scope.name)-\(name)-subscription"
			} else if let zone = zone {
				return "\(scope.name)-\(zone.zoneID.zoneName)-(all)-subscription"
			} else {
				return "\(scope.name)-(all)-subscription"
			}
		}
		
		func subscription(in scope: CKDatabase.Scope) -> CKSubscription {
			let sub: CKSubscription
			
			if scope == .shared {
				sub = CKDatabaseSubscription(subscriptionID: id(in: scope))
				(sub as? CKDatabaseSubscription)?.recordType = recordName
			} else if let name = recordName {
				sub = CKQuerySubscription(recordType: name, predicate: predicate ?? NSPredicate(value: true), subscriptionID: id(in: scope), options: options)
			} else if let zoneID = zone?.zoneID {
				sub = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: id(in: scope))
			} else {
				sub = CKDatabaseSubscription(subscriptionID: id(in: scope))
			}

			let noteInfo = CKSubscription.NotificationInfo()
			
			noteInfo.shouldSendContentAvailable = true
			sub.notificationInfo = noteInfo
			return sub
		}
	}
	
}
