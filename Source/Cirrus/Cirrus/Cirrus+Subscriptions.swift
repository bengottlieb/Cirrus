//
//  Cirrus+Subscriptions.swift
//  Cirrus+Subscriptions
//
//  Created by Ben Gottlieb on 7/20/21.
//

import CloudKit


extension Cirrus {
	public struct SubscriptionInfo {
		public var recordName: String?
		public var zone: CKRecordZone?
		public var predicate: NSPredicate?
		public var options: CKQuerySubscription.Options
		
		public init(recordName: String? = nil, zone: CKRecordZone? = nil, predicate: NSPredicate? = nil, options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]) {
			self.recordName = recordName
			self.zone = zone
			self.predicate = predicate
			self.options = options
		}

		public func id(in scope: CKDatabase.Scope) -> CKSubscription.ID {
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
