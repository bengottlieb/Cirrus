//
//  NSManagedObject+SA_Additions.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import CoreData
import Suite

extension NSManagedObject {
	public class var didInsertNotification: Notification.Name { return Notification.Name("NSManagedObject_DidInsertNotification_\(self)") }
	public class var willDeleteNotification: Notification.Name { return Notification.Name("NSManagedObject_WillDeleteNotification_\(self)") }
	public class var didDeleteNotification: Notification.Name { return Notification.Name("NSManagedObject_DidDeleteNotification_\(self)") }

	public class func entityName(in moc: NSManagedObjectContext) -> String {
		let name = NSStringFromClass(self)

		for entity in moc.persistentStoreCoordinator?.managedObjectModel.entities ?? [] {
			if entity.managedObjectClassName == name, let entityName = entity.name { return entityName }
		}
		
		var trimmed = name.components(separatedBy: ".").last!
		if trimmed.hasSuffix("MO") { trimmed = String(trimmed[..<trimmed.index(trimmed.count - 2)]) }
		return trimmed
	}
}
