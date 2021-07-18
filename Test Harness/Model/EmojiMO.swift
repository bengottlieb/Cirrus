//
//  EmojiMO.swift
//  Model
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class EmojiMO: NSManagedObject {
	@NSManaged public var uuid: String
	@NSManaged public var badge: EmojiBadgeMO?
	
	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
}
