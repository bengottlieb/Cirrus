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
	public let viewContext: NSManagedObjectContext
	public let importContext: NSManagedObjectContext
	public var autoSyncOnAuthentication = true
	var cancelBag: Set<AnyCancellable> = []
	public var isSyncing = false { didSet { self.objectWillChange.sendOnMain() }}

	public func newViewContext() -> NSManagedObjectContext {
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = viewContext
		return context
	}
	public static func setup(name: String, containerIdentifier: String? = nil, managedObjectModel model: NSManagedObjectModel? = nil, bundle: Bundle = .main) {
		instance = .init(name: name, containerIdentifier: containerIdentifier, managedObjectModel: model, bundle: bundle)
	}
	
	public func entity(named name: String) -> NSEntityDescription {
		container.persistentStoreCoordinator.managedObjectModel.entitiesByName[name]!
	}
    
	public init(name: String, containerIdentifier: String?, managedObjectModel model: NSManagedObjectModel?, bundle: Bundle) {
		AppGroupPersistentContainer.applicationGroupIdentifier = containerIdentifier
		self.container = AppGroupPersistentContainer(name: name, managedObjectModel: model ?? NSManagedObjectModel(contentsOf: bundle.url(forResource: name, withExtension: "momd")!)!)
		
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

	public func sync(fromBeginning: Bool = false, in db: CKDatabase? = nil) async throws {
		if isSyncing { return }
		logg("Sync Starting", .mild)
		isSyncing = true
		let isFirstSync = await importContext.perform { self.importContext.isEmpty }
		
		var database: CKDatabase! = db
		if database == nil { database = await Cirrus.instance.container.privateCloudDatabase }
		let zoneIDs = try await CKFetchDatabaseChangesOperation(database: database).changedZones().compactMap { $0.changedZoneID }
		
		let queryType: CKDatabase.RecordChangesQueryType = fromBeginning ? .all : (isFirstSync ? .createdOnly : .recent)
		
		do {
			for try await change in database.changes(in: zoneIDs, queryType: queryType) {
				if Logger.instance.level == .verbose {
					switch change {
					case .deleted(_, let type): if !isFirstSync { logg("Deleted \(type)") }
					case .changed(let id, let record): logg("Received \(record.recordType): \(id)")
					case .badRecord: logg("Bad Record")
					}
				}
				await Cirrus.instance.configuration.synchronizer?.process(downloadedChange: change)
			}
			await Cirrus.instance.configuration.synchronizer?.finishImporting()
			await Cirrus.instance.configuration.synchronizer?.uploadLocalChanges()
			Cirrus.Notifications.syncCompleted.notify()
			isSyncing = false
		}
		logg("Sync Completed", .mild)
	}
}
