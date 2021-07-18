//
//  Cirrus.Errors.swift
//  Cirrus.Errors
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

extension Cirrus {
	public func handleReceivedError(_ error: Error) {
		if let cloudErr = error as? CKError {
			switch cloudErr.code {
			case .missingEntitlement:
				logg(error: error, "Missing CloudKit Entitlement")
				
			case .notAuthenticated:
				DispatchQueue.onMain { self.state = .notLoggedIn }
				
			default: break
			}
		}
	}
}

public extension Cirrus {
	struct MultipleErrors: Error, LocalizedError {
		let errors: [Error]
		
		public var errorDescription: String? { "\(errors.count) Errors" }
	}
}

extension Error {
	var allErrors: [Error] {
		if let multi = self as? Cirrus.MultipleErrors { return multi.errors }
		return [self]
	}
	
	var ckRecord: CKRecord? {
		let info = (self as NSError).userInfo
		return info["ServerRecord"] as? CKRecord
	}
}
