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
		
		state = .signingIn
		do {
			switch try await container.accountStatus() {
			case .couldNotDetermine, .noAccount, .restricted, .temporarilyUnavailable:
				state = .denied
				
			case .available:
				let id = try await container.userRecordID()
				self.state = .authenticated(id)
				
			default:
				state = .notLoggedIn
			}
		} catch let error as NSError {
			state = .failed(error)
			throw error
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
