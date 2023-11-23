//
//  Cirrus.UserData.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

extension Cirrus {
	func userSignedIn(as id: CKRecord.ID, offline: Bool) {
		cloudQuotaExceeded = false
		state = offline ? .offline(id) : .authenticated(id)
		if localState.lastSignedInUserID != id {
			Notifications.currentUserChanged.notify(localState.lastSignedInUserID)
			localState.lastSignedInUserID = id
		}
		Notifications.userSignedIn.notify()
	}
}
