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
	@ObservedObject var dataStore = SyncedContainer.instance
	@State var clearing = false
	@Environment(\.managedObjectContext) var context
	@FetchRequest(entity: SyncedContainer.instance.entity(named: "Emoji"), sortDescriptors: [NSSortDescriptor(key: "uuid", ascending: true)], predicate: nil, animation: .linear) var emoji: FetchedResults<EmojiMO>
	
	var body: some View {
		VStack() {
			ScrollView() {
				ForEach(emoji) { emoji in
					EmojiRow(emoji: emoji)
					.padding(.horizontal)
					.padding(.vertical, 4)
				}
			}
			if clearing {
				ProgressView()
			} else {
				HStack() {
					Button("Clear All") {
						clearing = true
						Task() {
							try? await Cirrus.instance.container.privateCloudDatabase.deleteAll(from: ["emojiBadge", "emoji", "badge"], in: Cirrus.instance.zone(named: "emoji"))
							try? await SyncedContainer.instance.sync()
							clearing = false
						}
					}
					.padding()
					
					Button("Add 1000") {
						addEmoji(1000)
					}
					.padding()
				}
			}
		}
		.navigationTitle("Emoji - \(SyncedContainer.instance.viewContext.count(of: "Emoji"))")
		.navigationBarItems(leading: syncButton, trailing: Button(action:  { addEmoji(1) }) { Image(.plus_app) })
    }
	
	@ViewBuilder var syncButton: some View {
		if SyncedContainer.instance.isSyncing {
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
			try? await SyncedContainer.instance.sync(fromBeginning: fromBeginning)
		  }
	}
	
	func addEmoji(_ count: Int) {
		Task {
			for _ in 0..<count {
				let emoji = Emoji.randomEmoji(max: 2)
				if let object: EmojiMO = SyncedContainer.instance.viewContext.insertObject() {
					object.emoji = emoji.emoji
					object.initial = emoji.emoji
				}
			}
			SyncedContainer.instance.viewContext.saveContext()
//			try await Cirrus.instance.container.privateCloudDatabase.save(records: [CKRecord(emoji)!])
			sync()
		}
	}
}

struct EmojiListView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiListView()
			 .environment(\.managedObjectContext, SyncedContainer.instance.viewContext)
    }
}
