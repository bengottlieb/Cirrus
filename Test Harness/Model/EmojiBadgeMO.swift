//
//  EmojiBadgeMO.swift
//  EmojiBadgeMO
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class EmojiBadgeMO: NSManagedObject {
	@NSManaged public var uuid: String
	@NSManaged public var emoji: EmojiMO?
	@NSManaged public var badge: BadgeMO?
	
	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
}

