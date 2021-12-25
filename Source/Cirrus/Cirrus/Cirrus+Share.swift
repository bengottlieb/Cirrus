//
//  Cirrus+Share.swift
//  
//
//  Created by Ben Gottlieb on 12/22/21.
//

import CloudKit

public extension Cirrus {
	func accept(share: CKShare.Metadata) async throws {
		if share.participantStatus != .pending { return }
		
		let op = CKAcceptSharesOperation(shareMetadatas: [share])
		
		_ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			op.acceptSharesResultBlock = { result in
				switch result {
				case .success:
					continuation.resume()
					
				case .failure(let err):
					continuation.resume(throwing: err)
				}
			}
			
			container.add(op)
		}
	}
}

