//
//  EmojiListView.swift
//  EmojiListView
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CloudKit
import SwiftUI

struct EmojiListView: View {
	@ObservedObject var dataStore = DataStore.instance
	@State var clearing = false
	@Environment(\.managedObjectContext) var context
	@FetchRequest(entity: DataStore.instance.entity(named: "Emoji"), sortDescriptors: [NSSortDescriptor(key: "emoji", ascending: true)], predicate: nil, animation: .linear) var emoji: FetchedResults<EmojiMO>
	
	var body: some View {
		ScrollView() {
			VStack() {
				ForEach(emoji) { emoji in
					EmojiRow(emoji: emoji)
					.padding(.horizontal)
					.padding(.vertical, 4)
				}
				
				if clearing {
					ProgressView()
				} else {
					Button("Clear All") {
						clearing = true
						Task() {
							try? await Cirrus.instance.container.privateCloudDatabase.deleteAll(from: ["emojiBadge", "emoji", "badge"], in: Cirrus.instance.zone(named: "emoji"))
							try? await DataStore.instance.sync()
							clearing = false
						}
					}
				}
			}
		}
		.navigationTitle("Emoji")
		.navigationBarItems(leading: syncButton, trailing: Button(action: addEmoji) { Image(.plus_app) })
    }
	
	@ViewBuilder var syncButton: some View {
		if DataStore.instance.isSyncing {
			ProgressView()
		} else {
			Button(action: { sync() }) { Image(.arrow_clockwise) }
			.simultaneousGesture(LongPressGesture().onEnded { _ in
				sync(fromBeginning: true)
			})
		}
	}
	
	func sync(fromBeginning: Bool = false) {
		Task() {
			try? await DataStore.instance.sync(fromBeginning: fromBeginning)
		  }
	}
	
	func addEmoji() {
		Task {
			let emoji = Emoji.randomEmoji(max: 3)
			try await Cirrus.instance.container.privateCloudDatabase.save(records: [CKRecord(emoji)!])
			sync()
		}
	}
}

struct EmojiListView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiListView()
			 .environment(\.managedObjectContext, DataStore.instance.viewContext)
    }
}
