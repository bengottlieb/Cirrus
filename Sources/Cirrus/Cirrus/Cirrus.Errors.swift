//
//  Cirrus.Errors.swift
//  Cirrus.Errors
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

extension Cirrus {
	@discardableResult public func shouldCancelAfterError(_ error: Error) -> Bool { shouldCancelAfterError("", error) }
	@discardableResult public func shouldCancelAfterError(_ label: String, _ error: Error) -> Bool {
		if let multiple = error as? MultipleErrors {
			if let primary = multiple.primary {
				return shouldCancelAfterError(label, primary)
			} else {
				var result = false
				for error in multiple.errors {
					if shouldCancelAfterError(label, error) { result = true }
				}
				return result
			}
		}
		if error.isOffline {
			state = state.convertToOffline()
			return true
		} else if let cloudErr = error.cloudKitErrorCode {
			switch cloudErr {
			case .quotaExceeded:
				cloudQuotaExceeded = true
				logg(error: error, "Quota exceeded")
				return true
				
			case .permissionFailure:
				logg(error: error, "\(label): Not signed in")
				DispatchQueue.onMain { self.state = .notLoggedIn }
				return true

			case .changeTokenExpired:
				Cirrus.instance.localState.changeTokens = .init()
				return true
				
			case .zoneNotFound:
				Task { try? await Cirrus.instance.setupZones(forceCreate: true) }
				return true

			case .missingEntitlement:
				logg(error: error, "\(label): Missing CloudKit Entitlement")
				return true

			case .notAuthenticated:
				print("\(label): Not signed in")
				DispatchQueue.onMain { self.state = .notLoggedIn }
				return true

			case .invalidArguments:
				print("\(label): Possibly missing index. \(error.localizedDescription)")
				return true

			case .limitExceeded:
				print("\(label): Too many records in the request, \(error.localizedDescription)")
				return true

			case .accountTemporarilyUnavailable:
				print("\(label): Account temporarily unavailable")
				DispatchQueue.onMain { Cirrus.instance.state = .temporaryUnavailable }
				return true

			default:
				print("\(label): Unexpected Error: \(error)")
				return false
			}
		}
		return false
	}
}

public extension Error {
	var cloudKitErrorCode: CKError.Code? {
		(self as? CKError)?.code
	}

	var isOffline: Bool {
		(self as NSError).code == -1009
	}
}

public extension Cirrus {
	struct MultipleErrors: Error, LocalizedError {
		let errors: [Error]
		var primary: Error?
		
		public var errorDescription: String? { "\(errors.count) Errors" }
		
		static func build(errors: [Error]) -> Error {
			if errors.count == 1 { return errors[0] }
			
			if errors.count > 1 {
				let code = (errors[0] as NSError).code
				
				if errors.filter({ ($0 as NSError).code != code }).isEmpty {
					return MultipleErrors(errors: errors, primary: errors[0])
				}
			}
			
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
