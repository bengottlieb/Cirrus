//
//  Emoji.swift
//  Emoji
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Foundation
import CloudKit

struct Emoji: CKRecordSeed {
	var recordID: CKRecord.ID? { CKRecord.ID(recordName: emoji, zoneID: Cirrus.instance.privateZones["emoji"]!.zoneID) }
	var recordZone: CKRecordZone? { Cirrus.instance.zone(named: "emoji", in: .private) }
	var parentRelationshipName: String? { nil }
	var savedRelationshipNames: [String] { [] }
	
	var recordType: CKRecord.RecordType { "emoji" }
	var locallyModifiedAt: Date? { nil }
	
	var savedFieldNames: [String] { ["emoji"] }
	
	func reference(for name: String, action: CKRecord.ReferenceAction = .none) -> CKRecord.Reference? { nil }
	subscript(key: String) -> CKRecordValue? {
		switch key {
		case "emoji": return emoji as CKRecordValue
		default: return nil
		}
	}
	
	var emoji: String
}

extension Emoji {
	static func cluster(count: Int) -> [Emoji] {
		Array(0..<count).map { _ in randomEmoji(max: Int32(Int32.random(to: 10) + 1)) }
	}
	
	static func random() -> String {
		let seeds = "💉🆕🌓🖐🏛⬇️🎵💦👴😰🌫☢✴️🍕🚋👽🚘🔸⏩🎿🎩💺🗼🕙🌶⏲🍨🍌📜🈲🎀🔨🚪⚫️⚡️🚿✔️🌃🐣📄🏳🍦🈶🐕🌤🏂⚰🚍✡💃👓🔱💒🚣💚👙🌒®️🔜🕋💋🎨©️💠🎎💷🏰➡️👐🏵🐬🌻📱🖊🎧🔓🏚🍙🌜🌇💐🐔⛩☝️🏹🎦⛵️🗝▪️🎊📋🆒🏑😤⚛🍬📵☎️✏️💄🌉〽️📕🖨🆚🎶↕️💀🕍♨️✋⬆️🚌◽️👹👱➰🚅⚔📺🌐🚤📫🚨🌁⏸🕉📎😆🈯️💳📯🌪⏭🙁🌼🎓🏄🚢🕹🏔📆0️⃣🔂🐯🈸🚯🏜💾🍖🕘😌😞🗑🌩↔️🚁💞🎾🍼🕢🏢💝👌🛍🗽🕥😠🌊🌧⏳💼🍢🙂🤓🚴🆖🐏🕑🗨🌍🉑☀️🏓🌌📢📗😏🌴🍔➖👬🕝💢📏☯🎰◼️🅱️🌬🍝📙👅🎗👭🏍🖕🕤🏕🐴🆗🎣🖖😗😯🗄👒🕶🍲🖍💵📤🚙⚒🐥🛏✖️#️⃣🐞🏪🗻🚗🐡🆑🏌👈👃🚾😔🌄🕒🛄💫🍒🕜☺️🍹💤2️⃣🛐💪👾😋🕞🎪🚦📊⌚️🎼✌️4️⃣😈🛋🌡🐮⛪️🚇🎈🍾👢🔌👘🚆🐹🐲🎏◾️🈵⁉️🛀🈹👀🕦🔘💎🛳✝🎥✅🃏🤕🚼☪🐵🍵♊️⛏🕎😖😣💣💏📘☮🎠⬛️‼️🚛🙍💆🚠❤️🎻8️⃣🐂🤗🕌🔮🐇🏋🚽👰◀️1️⃣🐁👆🙆🍤✉️🏁👛💂😺⛷🍑☁️🤑👶👇🔷🍽👪🙏😵🚺👻💖🔔🌕🈚️📴♎️👝🕟☔️🐸🎄Ⓜ️🍜♍️🎉😿⚱🔭🆙🦃9️⃣🌦😄🙅🚞🍁🎞🏊📇🗜➗⏬💘🎲😑💱🚓👺😾🔰🔥👄🙈💿😘👊🐳🐙🎍🦀🐐📽🔬🚶▶️☂📰🍈😡🔁🛡🔶🐩🈴🐎👥⚖🔦🗡🎷🚑🍰🔛👗⏪🀄️🔀🌰💛⛄️😴🍅🕚7️⃣🐾🙌🔊🛅🚄😶🆔🦁🌂📩⏺🏆📓🌎🍠🚜🔝☄🛌📑🌸💇🚸👠🐊🕐⛑❎🍞♌️🗃🅾️➕🍃💡🔆🏨🌑❓🏅💧🏷🐑📸➿🐜🐝🤘📂🆘😊🔹🛃😹💓6️⃣🐷🚧🏺👉📐↘️🎐💌🍭🗣💯🔟🐪"
		
		return "\(seeds.randomElement()!)"
	}
	
	static func randomEmoji(max: Int32 = 10) -> Emoji {
		
		var text = ""
		
		for _ in 0..<max {
			text += random()
		}
		return Emoji(emoji: text)
	}
}
