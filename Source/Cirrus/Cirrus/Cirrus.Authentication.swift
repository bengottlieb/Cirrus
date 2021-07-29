//
//  Cirrus.Authentication.swift
//  Cirrus.Authentication
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit

extension Cirrus {
	public func authenticate(evenIfOffline: Bool = false) async throws {
		guard state.isSignedOut || state == .temporaryUnavailable || (evenIfOffline && state.isOffline) else { return }
		
		if state != .temporaryUnavailable { DispatchQueue.onMain { self.state = .signingIn } }
		do {
			switch try await container.accountStatus() {
			case .couldNotDetermine, .noAccount, .restricted, .temporarilyUnavailable:
				DispatchQueue.onMain { self.state = .denied }
				
			case .available:
				let id = try await container.userRecordID()
				try await setupZones()
				DispatchQueue.onMain { self.userSignedIn(as: id) }

			default:
				DispatchQueue.onMain { self.state = .notLoggedIn }
			}
		} catch let error as NSError {
			print("Error when signing in: \((error as NSError).code)  \(error)\n \((error as NSError).domain)")
			switch (error.code, error.domain) {
			case (1028, "CKInternalErrorDomain"):
				DispatchQueue.onMain { self.state = .temporaryUnavailable }
				
			default:
				DispatchQueue.onMain { self.state = .failed(error) }
				throw error
			}
		}
	}
	
	func setupZones() async throws {
		zones = Dictionary(uniqueKeysWithValues: configuration.zoneNames.map { ($0, CKRecordZone(zoneName: $0)) })
		if let defaultZone = configuration.defaultZoneName { self.defaultRecordZone = zones[defaultZone] }
		if self.localState.lastCreatedZoneNamesList == configuration.zoneNames { return }
		let op = CKModifyRecordZonesOperation(recordZonesToSave: Array(zones.values), recordZoneIDsToDelete: nil)
		
		return try await withUnsafeThrowingContinuation { continuation in
			op.modifyRecordZonesResultBlock = { result in
				switch result {
				case .success:
					DispatchQueue.onMain { self.localState.lastCreatedZoneNamesList = self.configuration.zoneNames }
					continuation.resume()
				case .failure(let error): continuation.resume(throwing: error)
				}
			}
			container.privateCloudDatabase.add(op)
		}
	}
	
	public func signOut() {
		self.state = .notLoggedIn
		self.localState.lastSignedInUserID = nil
	}
}

extension Cirrus {
	public enum AuthenticationState: Equatable { case notLoggedIn, signingIn, tokenFailed, denied, authenticated(CKRecord.ID), offline(CKRecord.ID), failed(NSError), temporaryUnavailable
		
		public var isSignedIn: Bool {
			switch self {
			case .authenticated, .offline: return true
			default: return false
			}
		}

		public var isSignedOut: Bool {
			switch self {
			case .notLoggedIn, .tokenFailed, .denied: return true
			default: return false
			}
		}

		public var isOffline: Bool {
			switch self {
			case .offline: return true
			default: return false
			}
		}
		
		func convertToOffline() -> AuthenticationState {
			switch self {
			case .authenticated(let userID): return .offline(userID)
			case .offline: return self
			default: return .notLoggedIn
			}
		}
	}
	
}

@available(iOSApplicationExtension, unavailable)
extension Cirrus {
	public static func launchCloudSettings() {
		let url = URL(string: UIApplication.openSettingsURLString)!
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
}
