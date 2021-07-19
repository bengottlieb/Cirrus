//
//  Cirrus.Configuration.swift
//  Cirrus.Configuration
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Foundation
import CloudKit
import UIKit
import CoreData

extension Cirrus {
	public struct Configuration {
		public static var instance: Configuration!
		
		public var containerIdentifer: String
		public var zoneNames: [String] = []
		
		public var managedObjectIDField: String?
		public var syncedEntityNames: [String] = []
		
		public var importer: ManagedObjectImporter?
		public var entities: [CirrusManagedObjectConfiguration]?
	}
}

extension Cirrus.Configuration {
	func entityInfo(for entityDescription: NSEntityDescription?) -> CirrusManagedObjectConfiguration? {
		entities?.first { $0.entityDescription == entityDescription }
	}

	func entityInfo(for recordType: CKRecord.RecordType) -> CirrusManagedObjectConfiguration? {
		entities?.first { $0.recordType == recordType }
	}
	
	func shouldEntity(_ first: NSEntityDescription, sortBefore second: NSEntityDescription) -> Bool {
		let firstIndex = entities?.firstIndex { $0.entityName == first.name } ?? Int.max
		let secondIndex = entities?.firstIndex { $0.entityName == second.name } ?? Int.max
		
		return firstIndex <= secondIndex
	}
}
