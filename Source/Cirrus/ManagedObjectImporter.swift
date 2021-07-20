//
//  ManagedObjectImporter.swift
//  ManagedObjectImporter
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Suite
import CoreData

public protocol ManagedObjectImporter {
	func process(change: CKRecordChange) async
	func finishImporting() async
}

public class SimpleObjectImporter: ManagedObjectImporter {
	let context: NSManagedObjectContext
	let connector: ReferenceConnector
	
	public init(context: NSManagedObjectContext) {
		self.context = context
		self.connector = ReferenceConnector(context: context)
	}
	
	public func finishImporting() async {
		await context.perform {
			self.connector.connectUnresolved()
			self.context.saveContext(toDisk: true)
		}
	}
	
	public func process(change: CKRecordChange) async {
		guard let info = await Cirrus.instance.configuration.entityInfo(for: change.recordType) else { return }
		
		let idField = await Cirrus.instance.configuration.idField
		do {
			switch change {
			case .changed(let id, let record):
				try await context.perform {
					if let object = info.record(with: id, in: self.context) {
						try object.load(cloudKitRecord: record, using: self.connector)
					} else {
						let object = self.context.insertEntity(named: info.entityDescription.name!) as! SyncedManagedObject
						object.setValue(id.recordName, forKey: idField)
						try object.load(cloudKitRecord: record, using: self.connector)
					}
				}
				
			case .deleted(let id, _):
				if let object = info.record(with: id, in: context) {
					context.delete(object)
				}
			}
		} catch {
			print("Failed to change: \(error)")
		}
	}
}


