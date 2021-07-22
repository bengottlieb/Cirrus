//
//  EmojiListView.swift
//  EmojiListView
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite

struct EmojiListView: View {
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
				
				Button("Clear All") {
					Task() {
						try? await Cirrus.instance.container.privateCloudDatabase.deleteAll(from: ["emoji", "emojiBadge", "badge"], in: Cirrus.instance.zone(named: "emoji"))
					}
				}
			}
		}
		.navigationTitle("Emoji")
		.navigationBarItems(leading: Button(action: {
			Task() {
				try? await DataStore.instance.sync()
			}}) { Image(.arrow_clockwise) })
    }
}

struct EmojiListView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiListView()
			 .environment(\.managedObjectContext, DataStore.instance.viewContext)
    }
}
