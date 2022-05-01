//
//  CKAccountStatus.swift
//  
//
//  Created by Ben Gottlieb on 5/1/22.
//

import CloudKit

extension CKAccountStatus: CustomStringConvertible {
	public var description: String {
		switch self {
		case .couldNotDetermine: return "could not determine"
		case .available: return "available"
		case .restricted: return "restricted"
		case .noAccount: return "noAccount"
		case .temporarilyUnavailable: return "temporarilyUnavailable"
		@unknown default: return "unknown"
		}
	}
}
	
