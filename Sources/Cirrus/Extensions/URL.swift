//
//  URL.swift
//  URL
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite

extension URL {
	func isSameFile(as other: URL) -> Bool {
		do {
			if self.path == other.path { return true }
			let myAttr = try FileManager.default.attributesOfItem(atPath: self.path)
			let theirAttr = try FileManager.default.attributesOfItem(atPath: other.path)
			let mySize = myAttr[.size] as? UInt64 ?? UInt64.max - 1
			let theirSize = theirAttr[.size] as? UInt64 ?? UInt64.max - 2
			
			if mySize != theirSize { return false }
		
			return FileManager.default.contentsEqual(atPath: path, andPath: other.path)
		} catch {
			Suite.logg(error: error, "Error while checking files")
		}
		return false
	}
}
