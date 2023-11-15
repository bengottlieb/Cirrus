//
//  Cirrus.Authentication.swift
//  Cirrus.Authentication
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit

extension Cirrus {
	@MainActor public func authenticate(evenIfOffline: Bool = false) async throws {
		guard state.isSignedOut || state == .temporaryUnavailable || (evenIfOffline || !state.isOffline) else { return }
		
		if state != .temporaryUnavailable { self.state = .signingIn }
		do {
			let status = try await container.accountStatus()
			switch status {
			case .couldNotDetermine, .noAccount, .restricted, .temporarilyUnavailable:
				self.state = .denied
				
			case .available:
				let id = try await container.userRecordID()
				try await setupZones()
				self.userSignedIn(as: id)

			default:
				self.state = .notLoggedIn
			}
		} catch let error as NSError {
			cirrus_log("Error when signing in: \((error as NSError).code)  \(error)\n \((error as NSError).domain)")
			switch (error.code, error.domain) {
			case (1028, "CKInternalErrorDomain"):
				self.state = .temporaryUnavailable
				
			default:
				self.state = .failed(error)
				throw error
			}
		}
	}
	
	func setupZones(forceCreate: Bool = false) async throws {
		if !forceCreate, self.localState.lastCreatedZoneNamesList == configuration.zoneNames {
			self.privateZones = [:]
			self.sharedZones = []
			for name in configuration.zoneNames {
				privateZones[name] = CKRecordZone(zoneName: name)
			}
		} else {
			self.privateZones = try await container.privateCloudDatabase.setup(zones: configuration.zoneNames)
			self.sharedZones = try await container.sharedCloudDatabase.allZones()
        }
		if let defaultZone = configuration.defaultZoneName {
			self.defaultPrivateZone = privateZones[defaultZone]
		}
		await MainActor.run { self.localState.lastCreatedZoneNamesList = self.configuration.zoneNames }
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

#if os(iOS)
@available(iOSApplicationExtension, unavailable)
extension Cirrus {
	public static func launchCloudSettings() {
		let url = URL(string: UIApplication.openSettingsURLString)!
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
}
#endif
