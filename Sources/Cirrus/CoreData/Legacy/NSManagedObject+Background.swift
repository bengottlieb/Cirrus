//
//  NSManagedObject+Background.swift
//  
//
//  Created by ben on 2/2/21.
//

import Foundation
import CoreData

public extension NSManagedObject {
	@discardableResult
	func onBackground<Object: NSManagedObject>(perform: @escaping (NSManagedObjectContext, Object) -> Void) -> Bool {
		guard let myContext = self.moc else { return false }
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.parent = myContext
		
		guard let obj = moc.instantiate(self) as? Object else { return false }
		
		moc.perform {
			perform(moc, obj)
		}
		return true
	}

	func onBackground<Object: NSManagedObject, Result>(perform: @escaping (NSManagedObjectContext, Object) throws -> Result) async throws -> Result? {
		guard let myContext = self.moc else { return nil }
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.parent = myContext

		guard let obj = moc.instantiate(self) as? Object else { return nil }

		return try await withCheckedThrowingContinuation { continuation in
			moc.perform {
				do {
					continuation.resume(returning: try perform(moc, obj))
				} catch {
					continuation.resume(throwing: error)
				}
			}
		}
	}
}
