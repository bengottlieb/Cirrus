//
//  BadgeMO.swift
//  BadgeMO
//
//  Created by Ben Gottlieb on 7/18/21.
//

import CoreData

class BadgeMO: NSManagedObject {
	@NSManaged public var uuid: String
	@NSManaged public var emoji: EmojiBadgeMO?
	
	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
}
