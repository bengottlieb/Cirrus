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
			 Text(emoji.emoji)
			 Spacer()
			 
			 ForEach(Array(emoji.badges ?? [])) { emojiBadge in
				 Text(emojiBadge.badge?.content ?? "-")
			 }
			 
			 Button(action: addBadge) {
				 Image(.plus_bubble)
			 }
		 }
    }
	
	func addBadge() {
		let badgeEmoji = Emoji.random()
		
		let badge = DataStore.instance.badge(with: badgeEmoji)
		badge.content = badgeEmoji
		emoji.add(badge: badge)
		
		do {
			try emoji.managedObjectContext?.save()
		} catch {
			print("Error when saving: \(error)")
		}
	}
}
