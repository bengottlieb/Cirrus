//
//  EmojiRow.swift
//  EmojiRow
//
//  Created by Ben Gottlieb on 7/18/21.
//

import SwiftUI

struct EmojiRow: View {
	@ObservedObject var emoji: EmojiMO
	
	var body: some View {
		HStack() {
			Button(action: rebuild) {
				Text("\(emoji.emoji)(\(emoji.badges?.count ?? 0))")
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
		
		let badge = DataStore.instance.badge(with: badgeEmoji)
		badge.content = badgeEmoji
		emoji.add(badge: badge)
		save()
	}
	
	func save() {
		do {
			try emoji.managedObjectContext?.save()
		} catch {
			print("Error when saving: \(error)")
		}
	}
}
