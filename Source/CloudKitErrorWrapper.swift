//
//  tryCloud.swift
//  
//
//  Created by Ben Gottlieb on 11/22/22.
//

import Foundation
import CloudKit

public func tryCloud<Result>(_ block: @escaping () async throws -> Result) async -> Result? {
	do {
		return try await block()
	} catch {
		print("CloudKit function failed: \(error)")
		return nil
	}
}
