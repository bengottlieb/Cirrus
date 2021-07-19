//
//  EmojiBadgeMO.swift
//  EmojiBadgeMO
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class EmojiBadgeMO: SyncedManagedObject, Identifiable {
	@NSManaged public var uuid: String
	@NSManaged public var emoji: EmojiMO?
	@NSManaged public var badge: BadgeMO?
	
	var id: String { uuid }

	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
}

