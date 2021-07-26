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
	@NSManaged public var initial: String

	var id: String { uuid }
	
	
	override func awakeFromInsert() {
		self.uuid = UUID().uuidString
	}
	
	func add(badge: BadgeMO) {
		let link: EmojiBadgeMO = self.managedObjectContext!.insertObject()
		
		link.emoji = self
		link.badge = badge
	}
	
	func deleteBadge(withContent content: String) {
		for badge in badges ?? [] {
			if badge.badge?.content == content {
				badge.deleteFromContext()
				self.save()
				return
			}
		}
	}
	
	var sortedBadges: [(String, Int)] {
		var results: [String: Int] = [:]
		for badge in badges ?? [] {
			guard let content = badge.badge?.content else { continue }
			let current = results[content] ?? 0
			results[content] = current + 1
		}
		return Array(results.keys).sorted().map { ($0, results[$0] ?? 0) }
	}
}
