//
//  CKModifySubscriptionsOperation.swift
//  CKModifySubscriptionsOperation
//
//  Created by Ben Gottlieb on 7/20/21.
//

import CloudKit

extension CKModifySubscriptionsOperation {
	func save(in database: CKDatabase) async throws {
		if subscriptionsToSave.isEmpty { return }
        return try await withUnsafeThrowingContinuation { continuation in
			self.modifySubscriptionsResultBlock = { result in
				continuation.resume(with: result)
			}
			
			database.add(self)
		}
	}

}
