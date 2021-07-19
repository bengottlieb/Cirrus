//
//  BadgeMO.swift
//  BadgeMO
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class BadgeMO: SyncedManagedObject, Identifiable {
	@NSManaged public var uuid: String
	@NSManaged public var emojis: Set<EmojiBadgeMO>?
	@NSManaged public var content: String

	var id: String { uuid }

	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
}
