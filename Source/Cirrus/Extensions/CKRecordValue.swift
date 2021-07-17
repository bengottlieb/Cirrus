//
//  CKRecordValue.swift
//  CKRecordValue
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

	/* String, Date, Data, Bool, Int, UInt, Float, Double, [U]Int8 et al, CKReference / Record.Reference, CKAsset, CLLocation, Array */
	public func areEqual(_ lhs: CKRecordValue?, _ rhs: CKRecordValue?) -> Bool {
		if let left = lhs as? String, let right = rhs as? String { return left == right }
		if let left = lhs as? Date, let right = rhs as? Date { return left == right }
		if let left = lhs as? Data, let right = rhs as? Data { return left == right }
		if let left = lhs as? Bool, let right = rhs as? Bool { return left == right }
		if let left = lhs as? Int, let right = rhs as? Int { return left == right }
		if let left = lhs as? Double, let right = rhs as? Double { return left == right }
		if let left = lhs as? CKRecord.Reference, let right = rhs as? CKRecord.Reference { return left == right }
		if let left = (lhs as? CKAsset)?.fileURL!, let right = (rhs as? CKAsset)?.fileURL! { return left.isSameFile(as: right) }
		if let left = lhs as? CLLocation, let right = rhs as? CLLocation { return left == right }
		if let left = lhs as? [CKRecordValue], let right = rhs as? [CKRecordValue] {
			if left.count != right.count { return false }
			for (leftItem, rightItem) in zip(left, right) { if !areEqual(leftItem, rightItem) { return false }}
			return true
		}
		return false
	}
