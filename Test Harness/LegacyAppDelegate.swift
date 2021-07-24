//
//  LegacyAppDelegate.swift
//  LegacyAppDelegate
//
//  Created by Ben Gottlieb on 7/20/21.
//

import Foundation
import UIKit

class LegacyAppDelegate: NSObject, UIApplicationDelegate {
	override init() {
		super.init()
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		UIApplication.shared.registerForRemoteNotifications()
		return true
	}
	
	public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
					
		Task() {
			try? await SyncedContainer.instance.sync()
			completionHandler(.noData)
		}
	}

}
