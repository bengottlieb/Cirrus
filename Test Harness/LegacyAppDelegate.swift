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
	func applicationDidFinishLaunching(_ application: UIApplication) {
		print("Hello!")
	}
	public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
					
		completionHandler(.noData)
	}

}
