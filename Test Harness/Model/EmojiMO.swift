//
//  EmojiMO.swift
//  Model
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class EmojiMO: SyncedManagedObject, Identifiable {
	@NSManaged public var uuid: String
	@NSManaged public var badges: Set<EmojiBadgeMO>?
	@NSManaged public var emoji: String
	
	var id: String { uuid }
	
	
	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
	
	func add(badge: BadgeMO) {
		let link: EmojiBadgeMO = self.managedObjectContext!.insertObject()
		
		link.emoji = self
		link.badge = badge
	}
}
