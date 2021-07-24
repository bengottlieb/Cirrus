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
	
	static func badge(with emoji: String) -> BadgeMO {
		let viewContext = SyncedContainer.instance.viewContext
		let predicate = NSPredicate(format: "content == %@", emoji)
		if let found: BadgeMO = viewContext.fetchAny(matching: predicate) { return found }
		
		let badge: BadgeMO = viewContext.insertObject()
		
		badge.content = emoji
		return badge
		
	}
}
