//
//  CKRecordZone+Sharing.swift
//
//
//  Created by Ben Gottlieb on 11/15/23.
//

import CloudKit
import SwiftUI

extension CKDatabase {
	public func share(zoneID: CKRecordZone.ID, title: String, image: UIImage? = nil, readWrite: Bool = true) async throws -> CKShare {
		let recordID = CKRecord.ID(recordName: "cloudkit.zoneshare", zoneID: zoneID)
		
		if let record = try? await fetchRecord(withID: recordID) as? CKShare {
			record[CKShare.SystemFieldKey.thumbnailImageData] = image?.pngData()
			record[CKShare.SystemFieldKey.title] = title
			record.publicPermission = readWrite ? .readWrite : .readOnly

			Task { try? await save(record) }
			return record
		}
		let share = CKShare(recordZoneID: zoneID)
		
		share[CKShare.SystemFieldKey.thumbnailImageData] = image?.pngData()
		share[CKShare.SystemFieldKey.title] = title
		share.publicPermission = readWrite ? .readWrite : .readOnly
		let result = try await save(share)
		return result as? CKShare ?? share
	}
}
