//
//  CKRecord.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

#if canImport(UIKit)
import UIKit
#endif

// To do: This is a temporary fix, will need to be addressed by Apple
extension CKRecord: @unchecked Sendable { }
extension CKRecordZone: @unchecked Sendable { }

extension CKRecord {
	enum SharingError: Error { case noViewController }
	
	public func insertChanges(from dictionary: [String: CKRecordValue?]) {
		for (key, value) in dictionary {
			if !areEqual(self[key], value) {
				self[key] = value
			}
		}
	}
	
	#if os(iOS)
	public func share(withTitle title: String, permissions: CKShare.ParticipantPermission = .readOnly, in window: UIWindow?) async throws {
		guard let host = await window?.rootViewController else { throw SharingError.noViewController }
		
		let controller = await UICloudSharingController { shareController, prep in
			let share = CKShare(rootRecord: self)
			share[CKShare.SystemFieldKey.title] = title as CKRecordValue
			share.publicPermission = .readOnly
			
			Task {
				do {
					try await CKDatabase.private.save(records: [self, share])
					prep(share, CKContainer.default(), nil)
				} catch {
					prep(share, CKContainer.default(), error)
				}
			}
		}
		
		await host.show(controller, sender: nil)
	}
	#endif

	public convenience init?(_ seed: CKRecordSeed) {
		guard let id = seed.recordID else {
			self.init(recordType: seed.recordType)
			return nil
		}

		self.init(recordType: seed.recordType, recordID: id)
		for name in seed.savedFieldNames {
			self[name] = seed[name]
		}
		
		if let parentKey = seed.parentRelationshipName, let parentRef = seed.reference(for: parentKey, action: .none) {
			if let parent = seed[parentKey] as? SyncedManagedObject {
				(seed as? SyncedManagedObject)?.setDatabase(parent.database)
			}
			self.parent = parentRef
			self[parentKey] = seed.reference(for: parentKey, action: .deleteSelf)
		}
		
		for key in seed.savedRelationshipNames {
			if let reference = seed.reference(for: key, action: .none) {
				self[key] = reference
			}
		}
	}
}

public extension CKRecord {
	func copy(from record: CKRecord) {
		for field in self.allKeys() {
			if record[field] == nil { self[field] = nil }
		}
		for field in record.allKeys() {
			self[field] = record[field]
		}
	}
	
	func hasSameContent(as record: CKRecord) -> Bool {
		let keys = self.allKeys()
		if keys != record.allKeys() { return false }
		
		for key in keys {
			if !areEqual(self[key], record[key]) { return false }
		}
		return true
	}
}
