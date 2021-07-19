//
//  Emoji.swift
//  Emoji
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Foundation
import CloudKit

struct Emoji: CKRecordSeed {
	var recordID: CKRecord.ID? { CKRecord.ID(recordName: emoji, zoneID: Cirrus.instance.zones["emoji"]!.zoneID) }
	var recordZone: CKRecordZone? { Cirrus.instance.zone(named: "emoji") }
	var parentRelationshipName: String? { nil }
	var savedRelationshipNames: [String] { [] }
	
	var recordType: CKRecord.RecordType { "emoji" }
	
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
	static func cluser(count: Int) -> [Emoji] {
		Array(0..<count).map { _ in randomEmoji() }
	}
	
	static func random() -> String {
		let seeds = "💉🆕🌓🖐🏛⬇️🎵💦👴😰🌫☢✴️🍕🚋👽🚘🔸⏩🎿🎩💺🗼🕙🌶⏲🍨🍌📜🈲🎀🔨🚪⚫️⚡️🚿✔️🌃🐣📄🏳🍦🈶🐕🌤🏂⚰🚍✡💃👓🔱💒🚣💚👙🌒®️🔜🕋💋🎨©️💠🎎💷🏰➡️👐🏵🐬🌻📱🖊🎧🔓🏚🍙🌜🌇💐🐔⛩☝️🏹🎦⛵️🗝▪️🎊📋🆒🏑😤⚛🍬📵☎️✏️💄🌉〽️📕🖨🆚🎶↕️💀🕍♨️✋⬆️🚌◽️👹👱➰🚅⚔📺🌐🚤📫🚨🌁⏸🕉📎😆🈯️💳📯🌪⏭🙁🌼🎓🏄🚢🕹🏔📆0️⃣🔂🐯🈸🚯🏜💾🍖🕘😌😞🗑🌩↔️🚁💞🎾🍼🕢🏢💝👌🛍🗽🕥😠🌊🌧⏳💼🍢🙂🤓🚴🆖🐏🕑🗨🌍🉑☀️🏓🌌📢📗😏🌴🍔➖👬🕝💢📏☯🎰◼️🅱️🌬🍝📙👅🎗👭🏍🖕🕤🏕🐴🆗🎣🖖😗😯🗄👒🕶🍲🖍💵📤🚙⚒🐥🛏✖️#️⃣🐞🏪🗻🚗🐡🆑🏌👈👃🚾😔🌄🕒🛄💫🍒🕜☺️🍹💤2️⃣🛐💪👾😋🕞🎪🚦📊⌚️🎼✌️4️⃣😈🛋🌡🐮⛪️🚇🎈🍾👢🔌👘🚆🐹🐲🎏◾️🈵⁉️🛀🈹👀🕦🔘💎🛳✝🎥✅🃏🤕🚼☪🐵🍵♊️⛏🕎😖😣💣💏📘☮🎠⬛️‼️🚛🙍💆🚠❤️🎻8️⃣🐂🤗🕌🔮🐇🏋🚽👰◀️1️⃣🐁👆🙆🍤✉️🏁👛💂😺⛷🍑☁️🤑👶👇🔷🍽👪🙏😵🚺👻💖🔔🌕🈚️📴♎️👝🕟☔️🐸🎄Ⓜ️🍜♍️🎉😿⚱🔭🆙🦃9️⃣🌦😄🙅🚞🍁🎞🏊📇🗜➗⏬💘🎲😑💱🚓👺😾🔰🔥👄🙈💿😘👊🐳🐙🎍🦀🐐📽🔬🚶▶️☂📰🍈😡🔁🛡🔶🐩🈴🐎👥⚖🔦🗡🎷🚑🍰🔛👗⏪🀄️🔀🌰💛⛄️😴🍅🕚7️⃣🐾🙌🔊🛅🚄😶🆔🦁🌂📩⏺🏆📓🌎🍠🚜🔝☄🛌📑🌸💇🚸👠🐊🕐⛑❎🍞♌️🗃🅾️➕🍃💡🔆🏨🌑❓🏅💧🏷🐑📸➿🐜🐝🤘📂🆘😊🔹🛃😹💓6️⃣🐷🚧🏺👉📐↘️🎐💌🍭🗣💯🔟🐪"
		
		return "\(seeds.randomElement()!)"
	}
	
	static func randomEmoji() -> Emoji {
		
		var text = ""
		
		for _ in 0...(Int.random(to: 10) + 2) {
			text += random()
		}
		return Emoji(emoji: text)
	}
}
