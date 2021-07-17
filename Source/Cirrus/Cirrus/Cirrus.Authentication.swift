//
//  Cirrus.Authentication.swift
//  Cirrus.Authentication
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit

extension Cirrus {
	public func authenticate() async throws {
		guard state.isSignedOut else { return }
		
		DispatchQueue.onMain { self.state = .signingIn }
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
			DispatchQueue.onMain { self.state = .failed(error) }
			throw error
		}
	}
	
	func setupZones() async throws {
		zones = Dictionary(uniqueKeysWithValues: configuration.zoneNames.map { ($0, CKRecordZone(zoneName: $0)) })
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
}

extension Cirrus {
	public enum AuthenticationState: Equatable { case notLoggedIn, signingIn, tokenFailed, denied, authenticated(CKRecord.ID), failed(NSError)
		
		var isSignedOut: Bool {
			switch self {
			case .notLoggedIn, .tokenFailed, .denied: return true
			default: return false
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
