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
		if error.isOffline {
			state = state.convertToOffline()
		} else if let cloudErr = error as? CKError {
			switch cloudErr.code {
			case .missingEntitlement:
				logg(error: error, "Missing CloudKit Entitlement")
				
			case .notAuthenticated:
				DispatchQueue.onMain { self.state = .notLoggedIn }
				
				
			default:
				print("Unexpected Error: \(error)")
			}
		}
	}
}

public extension Cirrus {
	struct MultipleErrors: Error, LocalizedError {
		let errors: [Error]
		
		public var errorDescription: String? { "\(errors.count) Errors" }
		
		static func build(errors: [Error]) -> Error {
			if errors.count == 1 { return errors[0] }
			return MultipleErrors(errors: errors)
		}
	}
}

extension Error {
	var allErrors: [Error] {
		if let multi = self as? Cirrus.MultipleErrors { return multi.errors }
		return [self]
	}
	
	var serverRecord: CKRecord? {
		let info = (self as NSError).userInfo
		return info["ServerRecord"] as? CKRecord
	}
	
	var clientRecord: CKRecord? {
		let info = (self as NSError).userInfo
		return info["ClientRecord"] as? CKRecord
	}
}
