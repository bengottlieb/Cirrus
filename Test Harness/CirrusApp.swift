//
//  CirrusApp.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import SwiftUI



@main
struct CirrusApp: App {
	let configuration = Cirrus.Configuration(containerIdentifer: "iCloud.con.standalone.cloudkittesting", zoneNames: ["Cirrus Zone 1"])
	
	init() {
		Cirrus.configure(with: configuration)
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
