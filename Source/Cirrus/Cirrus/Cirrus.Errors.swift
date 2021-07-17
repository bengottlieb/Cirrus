//
//  Cirrus.Errors.swift
//  Cirrus.Errors
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Foundation
import CloudKit

public extension Cirrus {
	struct MultipleErrors: Error, LocalizedError {
		let errors: [Error]
		
		public var errorDescription: String? { "\(errors.count) Errors" }
	}
}

extension Error {
	var allErrors: [Error] {
		if let multi = self as? Cirrus.MultipleErrors { return multi.errors }
		return [self]
	}
	
	var ckRecord: CKRecord? {
		let info = (self as NSError).userInfo
		return info["ServerRecord"] as? CKRecord
	}
}
