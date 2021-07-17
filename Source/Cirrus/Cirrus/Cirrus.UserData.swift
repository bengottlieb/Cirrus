//
//  Cirrus.UserData.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

extension Cirrus {
	func userSignedIn(as id: CKRecord.ID) {
		state = .authenticated(id)
		if localState.lastSignedInUserID != id.recordName {
			Notifications.currentUserChanged.notify(localState.lastSignedInUserID)
			localState.lastSignedInUserID = id.recordName
		}
		Notifications.userSignedIn.notify()
	}
}
