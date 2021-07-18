//
//  ManagedObjectImporter.swift
//  ManagedObjectImporter
//
//  Created by Ben Gottlieb on 7/18/21.
//

import Foundation
import CoreData

public protocol ManagedObjectImporter {
	func process(change: CKRecordChange)
	func finishImporting()
}

public class SimpleObjectImporter: ManagedObjectImporter {
	let context: NSManagedObjectContext
	var unresolvedReferences: [UnresolvedReference] = []
	
	public init(context: NSManagedObjectContext) {
		self.context = context
	}
	
	public func finishImporting() {
		print("All done!")
		try? context.save()
	}
	
	public func process(change: CKRecordChange) {
		guard let info = Cirrus.instance.configuration.entities?[change.recordType] else { return }
		
		switch change {
		case .changed(let id, let record):
			do {
				if let object = info.record(with: id, in: context) {
					unresolvedReferences += try object.load(cloudKitRecord: record)
				} else {
					let object = context.insertEntity(named: info.entityDescription.name!)
					unresolvedReferences += try object.load(cloudKitRecord: record)
				}
			} catch {
			}
			
		case .deleted(let id, _):
			if let object = info.record(with: id, in: context) {
				context.delete(object)
			}
		}
	}
}


