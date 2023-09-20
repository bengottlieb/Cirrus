//
//  EmojiRow.swift
//  EmojiRow
//
//  Created by Ben Gottlieb on 7/18/21.
//

import SwiftUI
import Suite

struct EmojiRow: View {
	@ObservedObject var emoji: EmojiMO
	
	var suffix: String {
		var content: [String] = []
		
		if emoji.initial != emoji.emoji { content.append(emoji.initial) }
		if let count = emoji.badges?.count, count > 0 { content.append("\(count)") }
		if content.isEmpty { return "" }
		return "[\(content.joined(separator: ", "))]"
	}
	
	var body: some View {
		HStack() {
			Button(action: rebuild) {
				Text("\(emoji.emoji)\(suffix)")
			}
			Spacer()
			
			let badges = emoji.sortedBadges
			ForEach(badges.indices, id: \.self) { index in
				let string = badges[index].0
				let count = badges[index].1
				
				Button(action: { deleteBadge(string) }) {
					HStack(spacing: 1) {
						Text(string)
						if count > 0 { Text("\(count)").font(.caption) }
					}
				}
				.buttonStyle(PlainButtonStyle())
			}
			
			Button(action: addBadge) {
				Image(.plus_bubble)
			}
		}
	}
	
	func rebuild() {
		emoji.emoji = Emoji.randomEmoji(max: 3).emoji
		emoji.save()
	}
	
	func deleteBadge(_ string: String) {
		emoji.deleteBadge(withContent: string)
	}
	
	func deleteBadge(_ emojiBadge: EmojiBadgeMO) {
		emojiBadge.deleteFromContext()
		save()
	}
	
	func addBadge() {
		let badgeEmoji = "\("📛🍏🎖💡⚙️".randomElement()!)"
		
		let badge = BadgeMO.badge(with: badgeEmoji)
		badge.content = badgeEmoji
		emoji.add(badge: badge)
		save()
	}
	
	func save() {
		do {
			try emoji.managedObjectContext?.save()
		} catch {
			logg("Error when saving: \(error)")
		}
	}
}
