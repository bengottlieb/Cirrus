//
//  CKRecordZone+Sharing.swift
//
//
//  Created by Ben Gottlieb on 11/15/23.
//

import CloudKit
import SwiftUI

extension CKDatabase {
	public func share(zoneID: CKRecordZone.ID, readWrite: Bool = false) async throws -> CKShare {
		let share = CKShare(recordZoneID: zoneID)
		share.publicPermission = readWrite ? .readWrite : .readOnly
		let result = try await save(share)
		return result as? CKShare ?? share
	}
}
