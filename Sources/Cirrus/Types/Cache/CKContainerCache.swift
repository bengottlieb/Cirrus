//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/24/23.
//

import CloudKit

public typealias RecordTypeTranslator = (CKRecord.RecordType) -> WrappedCKRecord.Type?


public class CKContainerCache {
	
	public static var instance: CKContainerCache!
	
	let url: URL
	let translator: RecordTypeTranslator
	
	public static func setup(url: URL, translator: @escaping RecordTypeTranslator) {
		instance = CKContainerCache(url: url, translator: translator)
	}
	
	public func database(for scope: CKDatabase.Scope) -> CKDatabaseCache {
		switch scope {
		case .private: return self.private
		case .public: return self.public
		case .shared: return self.shared
		@unknown default:
			return self.private
		}
	}
	
	init(url: URL, translator: @escaping RecordTypeTranslator = { _ in nil}) {
		self.url = url
		self.translator = translator
		print("Loading cache at \(url.path)")
	}
	
	public lazy var `private` = CKDatabaseCache(scope: .private, in: self)
	public lazy var `public` = CKDatabaseCache(scope: .public, in: self)
	public lazy var shared = CKDatabaseCache(scope: .shared, in: self)
}
