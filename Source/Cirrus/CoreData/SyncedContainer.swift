//
//  SyncedContainer.swift
//  SyncedContainer
//
//  Created by Ben Gottlieb on 7/24/21.
//

import CoreData
import CloudKit
import Suite

public class SyncedContainer: ObservableObject {
	public static var instance: SyncedContainer!
	
	public let container: AppGroupPersistentContainer
	public var mutability: Mutability
	public let viewContext: NSManagedObjectContext
	public let importContext: NSManagedObjectContext
	public var autoSyncOnAuthentication = true
	var cancelBag: Set<AnyCancellable> = []
	public var isSyncing = false { didSet { self.objectWillChange.sendOnMain() }}

	public static func setup(name: String, containerIdentifier: String? = nil, managedObjectModel model: NSManagedObjectModel? = nil, bundle: Bundle = .main, mutability: Mutability = .normal) {
		instance = .init(name: name, containerIdentifier: containerIdentifier, managedObjectModel: model, bundle: bundle, mutability: mutability)
	}
	
	public func entity(named name: String) -> NSEntityDescription {
		container.persistentStoreCoordinator.managedObjectModel.entitiesByName[name]!
	}

	public init(name: String, containerIdentifier: String?, managedObjectModel model: NSManagedObjectModel?, bundle: Bundle, mutability: Mutability) {
		AppGroupPersistentContainer.applicationGroupIdentifier = containerIdentifier
		self.container = AppGroupPersistentContainer(name: name, managedObjectModel: model ?? NSManagedObjectModel(contentsOf: bundle.url(forResource: name, withExtension: "momd")!)!)
		self.mutability = mutability
		
		self.container.loadPersistentStores { desc, error in
			Studio.logg(error: error, "Problem loading persistent stores in a SyncedContainer")
		}
		
		viewContext = container.viewContext
		importContext = container.newBackgroundContext()
		
		//viewContext.automaticallyMergesChangesFromParent = true
		
		Cirrus.Notifications.userSignedIn.publisher()
			.sink { note in
				if self.autoSyncOnAuthentication {
					Task() { try? await self.sync() } }
			}
			.store(in: &cancelBag)
		
		Notification.Name.NSManagedObjectContextDidSave.publisher()
			.sink { note in
				if let context = note.object as? NSManagedObjectContext, context.persistentStoreCoordinator == self.container.persistentStoreCoordinator {
					if context != self.viewContext {
						self.viewContext.perform { self.viewContext.mergeChanges(fromContextDidSave: note) }
					}
					if context != self.importContext {
						self.importContext.perform { self.importContext.mergeChanges(fromContextDidSave: note) }
					}
				}
			}
			.store(in: &cancelBag)
	}

	public func sync(fromBeginning: Bool = false, zones: [CKRecordZone]? = nil) async throws {
		logg("Sync Starting", .mild)
		isSyncing = true
		var zoneIDs = zones?.map { $0.zoneID }
		if zoneIDs == nil { zoneIDs = await Cirrus.instance.allZoneIDs }
		do {
			for try await change in await Cirrus.instance.container.privateCloudDatabase.changes(in: zoneIDs ?? [], fromBeginning: fromBeginning) {
				if Logger.instance.level == .verbose {
					switch change {
					case .deleted(_, let type): print("Deleted \(type)")
					case .changed(let id, let record): print("Received \(record.recordType): \(id)")
					case .badRecord: print("Bad Record")
					}
				}
				await Cirrus.instance.configuration.synchronizer?.process(downloadedChange: change)
			}
			await Cirrus.instance.configuration.synchronizer?.finishImporting()
			await Cirrus.instance.configuration.synchronizer?.uploadLocalChanges()
			isSyncing = false
		}
		logg("Sync Completed", .mild)
	}

	public enum Mutability: Int { case normal, readOnlyCloud, readOnly
		public var isReadOnlyForCloudOps: Bool { return self != .normal }
		public var isReadOnlyForCoreData: Bool { return self == .readOnly }
	}
}
