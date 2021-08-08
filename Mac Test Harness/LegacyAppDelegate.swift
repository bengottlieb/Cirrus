//
//  LegacyAppDelegate.swift
//  LegacyAppDelegate
//
//  Created by Ben Gottlieb on 8/5/21.
//

import Cocoa

class LegacyAppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ notification: Notification) {
		print("Did Finish Launching")
		NSApp.registerForRemoteNotifications()
	}
	
	func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
		print("didReceiveRemoteNotification")
		Task() {
			try? await SyncedContainer.instance.sync()
		}
	}
}
