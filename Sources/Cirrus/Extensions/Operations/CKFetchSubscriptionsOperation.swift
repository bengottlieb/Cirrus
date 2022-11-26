//
//  CKFetchSubscriptionsOperation.swift
//  CKFetchSubscriptionsOperation
//
//  Created by Ben Gottlieb on 7/20/21.
//

import CloudKit

extension CKFetchSubscriptionsOperation {
	func fetchAll(in database: CKDatabase) async throws -> [CKSubscription.ID: CKSubscription] {
		var errors: [Error] = []
		var subscriptions: [CKSubscription.ID: CKSubscription] = [:]
		
		return try await withUnsafeThrowingContinuation { continuation in
			self.perSubscriptionResultBlock = { id, result in
				switch result {
				case .failure(let err): errors.append(err)
				case .success(let sub): subscriptions[id] = sub
				}
			}
			
			self.fetchSubscriptionsResultBlock = { result in
				switch result {
				case .failure(let error):
					errors.append(error)
					continuation.resume(throwing: Cirrus.MultipleErrors.build(errors: errors))
					
				case .success:
					continuation.resume(returning: subscriptions)
					
				}
			}
			
			database.add(self)
		}
	}
}
