//
//  EmojiMO.swift
//  Model
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class EmojiMO: SyncedManagedObject, Identifiable {
	@NSManaged public var uuid: String
	@NSManaged public var badge: EmojiBadgeMO?
	@NSManaged public var emoji: String
	
	var id: String { uuid }
	
	
	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
}
