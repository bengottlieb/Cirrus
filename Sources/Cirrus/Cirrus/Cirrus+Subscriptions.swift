//
//  Cirrus+Subscriptions.swift
//  Cirrus+Subscriptions
//
//  Created by Ben Gottlieb on 7/20/21.
//

import CloudKit
import Suite

public extension CKDatabase {
	func setupSubscriptions(_ subs: [Cirrus.SubscriptionInfo]) async throws {
		let ids = subs.map { $0.id }
		let op = CKFetchSubscriptionsOperation(subscriptionIDs: ids)
		var creationError: Error?
		
		do {
			let existing = try await op.fetchAll(in: self)
			let newSubs = subs.filter { $0.scope == databaseScope && existing[$0.id] == nil }.map { $0.subscription }
			
			let modifyOp = CKModifySubscriptionsOperation(subscriptionsToSave: newSubs, subscriptionIDsToDelete: nil)
			modifyOp.perSubscriptionSaveBlock = { id, result in
				switch result {
				case .success: break
					
				case .failure(let error):
					creationError = error
				}
			}
			
			try await modifyOp.save(in: self)
			if let creationError { throw creationError }
		} catch {
			logg(error: error, "Failed to fetch/setup subscriptions")
			await Cirrus.instance.shouldCancelAfterError(error)
		}
		
	}
}

extension Cirrus {
	public struct SubscriptionInfo {
		public var recordName: String?
		public var zone: CKRecordZone?
		public var predicate: NSPredicate?
		public var options: CKQuerySubscription.Options
		public let scope: CKDatabase.Scope
		
		public init(scope: CKDatabase.Scope, recordName: String? = nil, zone: CKRecordZone? = nil, predicate: NSPredicate? = nil, options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]) {
			assert(zone == nil || scope != .shared, "Cannot create a zone-based subscription in the Shared database.")
			assert(zone == nil || recordName == nil, "Cannot create a zone-based subscription for a particular record type")
			self.recordName = recordName
			self.zone = zone
			self.predicate = predicate
			self.options = options
			self.scope = scope
		}

		public var id: CKSubscription.ID {
			var base = scope == .shared ? "shared:" : "private:"
			if let name = recordName {
				base += " (\(name))"
			} else {
				base += " [all]"
			}
			
			if let zone = zone {
				return base + " {\(zone.zoneID.zoneName)}"
			} else {
				return base
			}
		}
		
		var subscription: CKSubscription {
			let sub: CKSubscription
			
			if let zoneID = zone?.zoneID {
				sub = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: id)
			} else if scope == .shared {
				sub = CKDatabaseSubscription(subscriptionID: id)
				(sub as? CKDatabaseSubscription)?.recordType = recordName
			} else if let name = recordName {
				sub = CKQuerySubscription(recordType: name, predicate: predicate ?? NSPredicate(value: true), subscriptionID: id, options: options)
			} else {
				sub = CKDatabaseSubscription(subscriptionID: id)
			}

			let noteInfo = CKSubscription.NotificationInfo()
			
			noteInfo.shouldSendContentAvailable = true
			sub.notificationInfo = noteInfo
			return sub
		}
	}
	
}
