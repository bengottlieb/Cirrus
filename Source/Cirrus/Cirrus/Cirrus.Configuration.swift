//
//  Cirrus.Configuration.swift
//  Cirrus.Configuration
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Foundation
import CloudKit
import UIKit

extension Cirrus {
	public static func configure(with configuration: Configuration) {
		Configuration.instance = configuration
		instance.load(configuration: configuration)
	}
	
	func load(configuration config: Configuration) {
		assert(configuration == nil, "You can only configure Cirrus once.")
		configuration = config
		container = CKContainer(identifier: config.containerIdentifer)

		UIApplication.willEnterForegroundNotification.publisher()
			.sink() { _ in Task { try? await self.authenticate() }}
			.store(in: &cancelBag)
		
		Notification.Name.CKAccountChanged.publisher()
			.sink() { _ in Task { try? await self.authenticate() }}
			.store(in: &cancelBag)
	}
	
	public struct Configuration {
		public static var instance: Configuration!
		
		public var containerIdentifer: String
		public var zoneNames: [String] = []
		
		public var managedObjectIDField: String?
		public var syncedEntityNames: [String] = []
	}
}
