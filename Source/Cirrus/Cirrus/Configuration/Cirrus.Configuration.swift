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
		public var defaultZoneName: String?
		
		public var idField = "cirrus_uuid"					// every syncableManagedObject should have a string field with this name, used to generate the CKRecord.ID for that object
		public var statusField = "cirrus_status"			// also, it should have an Int32 field with this name, which contains the record's sync status
		public var syncedEntityNames: [String] = []

		public var synchronizer: ManagedObjectSynchronizer?
		public var entities: [CirrusManagedObjectConfiguration]?
		
		public var conflictResolver: ConflictResolver? = ConflictResolverNewerWins()
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
