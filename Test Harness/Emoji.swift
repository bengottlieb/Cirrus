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
	
	var recordType: CKRecord.RecordType { "emoji" }
	
	var savedFieldNames: [String] { ["emoji"] }
	
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
		Array(0..<count).map { _ in random() }
	}
	static func random() -> Emoji {
		let seeds = "💉 🆕 🌓 🖐 🏛 ⬇️ 🎵 💦 👴 😰 🌫 ☢ ✴️ 🍕 🚋 👽 🚘 🔸 ⏩ 🎿 🎩 💺 🗼 🕙 🌶 ⏲ 🍨 🍌 📜 🈲 🎀 🔨 🚪 ⚫️ ⚡️ 🚿 ✔️ 🌃 🐣 📄 🏳 🍦 🈶 🐕 🌤 🏂 ⚰ 🚍 ✡ 💃 👓 🔱 💒 🚣 💚 👙 🌒 ®️ 🔜 🕋 💋 🎨 ©️ 💠 🎎 💷 🏰 ➡️ 👐 🏵 🐬 🌻 📱 🖊 🎧 🔓 🏚 🍙 🌜 🌇 💐 🐔 ⛩ ☝️ 🏹 🎦 ⛵️ 🗝 ▪️ 🎊 📋 🆒 🏑 😤 ⚛ 🍬 📵 ☎️ ✏️ 💄 🌉 〽️ 📕 🖨 🆚 🎶 ↕️ 💀 🕍 ♨️ ✋ ⬆️ 🚌 ◽️ 👹 👱 ➰ 🚅 ⚔ 📺 🌐 🚤 📫 🚨 🌁 ⏸ 🕉 📎 😆 🈯️ 💳 📯 🌪 ⏭ 🙁 🌼 🎓 🏄 🚢 🕹 🏔 📆 0️⃣ 🔂 🐯 🈸 🚯 🏜 💾 🍖 🕘 😌 😞 🗑 🌩 ↔️ 🚁 💞 🎾 🍼 🕢 🏢 💝 👌 🛍 🗽 🕥 😠 🌊 🌧 ⏳ 💼 🍢 🙂 🤓 🚴 🆖 🐏 🕑 🗨 🌍 🉑 ☀️ 🏓 🌌 📢 📗 😏 🌴 🍔 ➖ 👬 🕝 💢 📏 ☯ 🎰 ◼️ 🅱️ 🌬 🍝 📙 👅 🎗 👭 🏍 🖕 🕤 🏕 🐴 🆗 🎣 🖖 😗 😯 🗄 👒 🕶 🍲 🖍 💵 📤 🚙 ⚒ 🐥 🛏 ✖️ #️⃣ 🐞 🏪 🗻 🚗 🐡 🆑 🏌 👈 👃 🚾 😔 🌄 🕒 🛄 💫 🍒 🕜 ☺️ 🍹 💤 2️⃣ 🛐 💪 👾 😋 🕞 🎪 🚦 📊 ⌚️ 🎼 ✌️ 4️⃣ 😈 🛋 🌡 🐮 ⛪️ 🚇 🎈 🍾 👢 🔌 👘 🚆 🐹 🐲 🎏 ◾️ 🈵 ⁉️ 🛀 🈹 👀 🕦 🔘 💎 🛳 ✝ 🎥 ✅ 🃏 🤕 🚼 ☪ 🐵 🍵 ♊️ ⛏ 🕎 😖 😣 💣 💏 📘 ☮ 🎠 ⬛️ ‼️ 🚛 🙍 💆 🚠 ❤️ 🎻 8️⃣ 🐂 🤗 🕌 🔮 🐇 🏋 🚽 👰 ◀️ 1️⃣ 🐁 👆 🙆 🍤 ✉️ 🏁 👛 💂 😺 ⛷ 🍑 ☁️ 🤑 👶 👇 🔷 🍽 👪 🙏 😵 🚺 👻 💖 🔔 🌕 🈚️ 📴 ♎️ 👝 🕟 ☔️ 🐸 🎄 Ⓜ️ 🍜 ♍️ 🎉 😿 ⚱ 🔭 🆙 🦃 9️⃣ 🌦 😄 🙅 🚞 🍁 🎞 🏊 📇 🗜 ➗ ⏬ 💘 🎲 😑 💱 🚓 👺 😾 🔰 🔥 👄 🙈 💿 😘 👊 🐳 🐙 🎍 🦀 🐐 📽 🔬 🚶 ▶️ ☂ 📰 🍈 😡 🔁 🛡 🔶 🐩 🈴 🐎 👥 ⚖ 🔦 🗡 🎷 🚑 🍰 🔛 👗 ⏪ 🀄️ 🔀 🌰 💛 ⛄️ 😴 🍅 🕚 7️⃣ 🐾 🙌 🔊 🛅 🚄 😶 🆔 🦁 🌂 📩 ⏺ 🏆 📓 🌎 🍠 🚜 🔝 ☄ 🛌 📑 🌸 💇 🚸 👠 🐊 🕐 ⛑ ❎ 🍞 ♌️ 🗃 🅾️ ➕ 🍃 💡 🔆 🏨 🌑 ❔ ❓ 🏅 💧 🏷 🐑 📸 ➿ 🐜 🐝 🤘 📂 🆘 😊 🔹 🛃 😹 💓 6️⃣ 🐷 🚧 🏺 👉 📐 ↘️ 🎐 💌 🍭 🗣 💯 🔟 🐪"
		
		var text = ""
		
		for _ in 2...Int.random(to: 10) {
			text += "\(seeds.randomElement()!)"
		}
		return Emoji(emoji: text)
	}
}
