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
			case .permissionFailure:
				logg(error: error, "Not signed in")
				DispatchQueue.onMain { self.state = .notLoggedIn }
				
			case .missingEntitlement:
				logg(error: error, "Missing CloudKit Entitlement")
				
			case .notAuthenticated:
				DispatchQueue.onMain { self.state = .notLoggedIn }
				
			case .invalidArguments:
				print("Possibly missing index. \(error.localizedDescription)")
				
			case .limitExceeded:
				print("Too many records in the request, \(error.localizedDescription)")
				
			case .accountTemporarilyUnavailable:
				DispatchQueue.onMain { Cirrus.instance.state = .temporaryUnavailable }
				
			default:
				print("Unexpected Error: \(error)")
			}
		}
	}
}

extension Error {
	var isOffline: Bool {
		(self as NSError).code == -1009
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
