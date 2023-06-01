//
//  AppGroupPersistentContainer.swift
//  AppGroupPersistentContainer
//
//  Created by Ben Gottlieb on 7/24/21.
//

import CoreData

@available(OSX 10.12, OSXApplicationExtension 10.12, iOS 10.0, iOSApplicationExtension 10.0, *)
open class AppGroupPersistentContainer: NSPersistentContainer {
	static var applicationGroupIdentifier: String?
	static var directoryName = "CirrusContainer"
	
	override open class func defaultDirectoryURL() -> URL {
		if let identifier = AppGroupPersistentContainer.applicationGroupIdentifier, let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
			return url.appendingPathComponent(AppGroupPersistentContainer.directoryName, conformingTo: .directory)
		}
		
		return super.defaultDirectoryURL()
	}
}

