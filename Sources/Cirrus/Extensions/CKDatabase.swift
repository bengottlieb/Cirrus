//
//  CKDatabase.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/17/21.
//

import Suite
import CloudKit

public protocol CKRecordProviding {
	var record: CKRecord { get }
	var modifiedAt: Date? { get }
}

extension CKRecord: CKRecordProviding {
	public var record: CKRecord { self }
	public var modifiedAt: Date? { modificationDate }
}

public extension CKDatabase {
	enum Kind: String { case `public`, `private`, shared
		var database: CKDatabase {
			switch self {
			case .public: return .public
			case .private: return .private
			case .shared: return .shared
			}
		}
	}
	
    static var `public`: CKDatabase { Cirrus.instance.container.publicCloudDatabase }
    static var `private`: CKDatabase { Cirrus.instance.container.privateCloudDatabase }
    static var `shared`: CKDatabase { Cirrus.instance.container.sharedCloudDatabase }

	enum RecordChangesQueryType { case recent, all, createdOnly }
	func records(ofType type: CKRecord.RecordType, matching predicate: NSPredicate = NSPredicate(value: true), sortedBy: [NSSortDescriptor] = [], in zoneID: CKRecordZone.ID? = nil) -> AsyncRecordSequence {
		let query = CKQuery(recordType: type, predicate: predicate)
		query.sortDescriptors = sortedBy
		
		
		let seq = AsyncRecordSequence(query: query, in: self, zoneID: zoneID)
		return seq
	}
	
	func resolve(reference: CKRecord.Reference?) async throws -> CKRecord? {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		guard let reference else { return nil }
		return try await record(for: reference.recordID)
	}

	func changes(in zoneIDs: [CKRecordZone.ID], queryType: RecordChangesQueryType = .recent, tokens: ChangeTokens) throws -> AsyncZoneChangesSequence {
		if Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }

		let noDefaultZone = zoneIDs.filter { $0.zoneName != "_defaultZone" }
		let seq = AsyncZoneChangesSequence(zoneIDs: noDefaultZone, in: self, queryType: queryType, tokens: tokens)

		return seq
	}
	
    func delete(recordID: CKRecord.ID) async throws -> Bool {
		 if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }

		 let result = try await delete(recordIDs: [recordID])
		return result.first == recordID
    }

    func delete(recordIDs: [CKRecord.ID]?) async throws -> [CKRecord.ID] {
		 guard let ids = recordIDs, ids.isNotEmpty else { return [] }
		 if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }

		let op = CKModifyRecordsOperation(recordIDsToDelete: recordIDs)
		do {
			return try await op.delete(from: self)
		} catch {
			await Cirrus.instance.shouldCancelAfterError(error)
			throw error
		}
	}
	
	func save(records: [CKRecordProviding]?, atomically: Bool = true, conflictResolver: ConflictResolver? = nil) async throws {
		guard let records = records, records.isNotEmpty else { return }
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }

		let chunkSize = 350
		let recordChunks = records.breakIntoChunks(ofSize: chunkSize)
		
		for chunk in recordChunks {
			let saved = chunk.map { $0.record }
			let op = CKModifyRecordsOperation(recordsToSave: saved)
			var resolver = conflictResolver
			if resolver == nil { resolver = await Cirrus.instance.configuration.conflictResolver }

			do {
				try await op.save(in: self)
			} catch {
				if let updatedRecords = try await resolver?.resolve(error: error, in: chunk, database: self) {
					try await save(records: updatedRecords, atomically: atomically, conflictResolver: conflictResolver)
				} else {
					await Cirrus.instance.shouldCancelAfterError(error)
					throw error
				}
			}
		}
	}
	
	func save(record: CKRecordProviding?, conflictResolver: ConflictResolver? = nil) async throws {
		guard let record = record else { return }
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }

        do {
            try await save(records: [record], conflictResolver: conflictResolver)
        } catch let error as CKError {
            switch error.cloudKitErrorCode {
            case .zoneNotFound:
                if await Cirrus.instance.autoCreateNewZones {
                    _ = try await createZone(named: record.record.recordID.zoneID.zoneName)
                    try await save(records: [record], conflictResolver: conflictResolver)
               } else {
                    throw error
                }
                
            default: 
                throw error
            }
        }
	}

	func delete(record: CKRecord?) async throws {
		guard let record = record else { return }
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		let op = CKModifyRecordsOperation(recordIDsToDelete: [record.recordID])
		_ = try await op.delete(from: self)
	}
	
	func fetchRecords(ofType type: CKRecord.RecordType, matching predicate: NSPredicate = .init(value: true), inZone: CKRecordZone.ID? = nil, keys: [CKRecord.FieldKey]? = nil, limit: Int = CKQueryOperation.maximumResults) async throws -> [CKRecord] {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		let query = CKQuery(recordType: type, predicate: predicate)
		do {
			var allResults: [CKRecord] = []
			var cursor: CKQueryOperation.Cursor?
			
			while true {
				let results: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
				
				if let cursor {
					results = try await self.records(continuingMatchFrom: cursor)
				} else {
					results = try await self.records(matching: query, inZoneWith: inZone, desiredKeys: keys, resultsLimit: limit)
				}
				
				allResults += results.matchResults.compactMap { result in
					switch result.1 {
					case .success(let record): return record
					case .failure: return nil
					}
				}
				
				guard let next = results.queryCursor, allResults.count < limit else { break }
				cursor = next
			}
			return allResults
		} catch let error as CKError {
			switch error.code {
			default:
				await Cirrus.instance.shouldCancelAfterError(error)
				throw error
			}
		}
	}
	
	func fetchRecord(withID id: CKRecord.ID) async throws -> CKRecord? {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		do {
			return try await record(for: id)
		} catch let error as CKError {
			switch error.code {
            case .zoneNotFound:
                return nil
                
			case .unknownItem:
				return nil
				
			default:
				await Cirrus.instance.shouldCancelAfterError(error)
				throw error
			}
		}
	}
}

extension CKDatabase {
	public func allZones() async throws -> [CKRecordZone] {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		let op = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
		var zones: [CKRecordZone] = []
		var errors: [Error] = []

		op.perRecordZoneResultBlock = { zoneID, zoneResult in
			switch zoneResult {
			case .success(let zone): zones.append(zone)
			case .failure(let err): errors.append(err)
			}
		}

		let found: [CKRecordZone] = try await withCheckedThrowingContinuation { continuation in
			op.fetchRecordZonesResultBlock = { result in
				switch result {
				case .success: continuation.resume(returning: zones)
				case .failure(let error): continuation.resume(throwing: error)
				}
			}
			
			self.add(op)
		}
		
		
		return found
	}
	
	public func fetchZone(withID target: CKRecordZone.ID) async throws -> CKRecordZone? {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		let all = try await allZones()
		return all.first { $0.zoneID.ownerName == target.ownerName && $0.zoneID.zoneName == target.zoneName }
	}
	
	public func createZone(named name: String) async throws -> CKRecordZone {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		if self == .private, let zone = await Cirrus.instance.privateZone(named: name) { return zone }
		
		let newZones = try await setup(zones: [name])
		if let newZone = newZones[name] { return newZone }
		throw Cirrus.CirrusError.unableToCreateZone
	}
	
	@discardableResult func setup(zones names: [String]) async throws -> [String: CKRecordZone] {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		let zones = Dictionary(uniqueKeysWithValues: names.map { ($0, CKRecordZone(zoneName: $0)) })
		let op = CKModifyRecordZonesOperation(recordZonesToSave: Array(zones.values), recordZoneIDsToDelete: nil)
		
		return try await withUnsafeThrowingContinuation { continuation in
			op.modifyRecordZonesResultBlock = { result in
				switch result {
				case .success:
					continuation.resume(returning: zones)
				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
			self.add(op)
		}
	}
	
	public struct FetchedRecordIDs {
		public var ids: [CKRecord.RecordType: [CKRecord.ID]] = [:]
		public var all: [CKRecord.ID] { ids.values.flatMap { $0 } }
		public var count: Int { ids.values.map { $0.count }.sum() }
		public func count(of type: CKRecord.RecordType) -> Int { ids[type]?.count ?? 0 }
	}
	
	public func allRecordIDs(from recordTypes: [CKRecord.RecordType], in zone: CKRecordZone? = nil) async throws -> FetchedRecordIDs {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		var results = FetchedRecordIDs()
		
		for recordType in recordTypes {
			let seq = AsyncRecordSequence(recordType: recordType, desiredKeys: [], in: self, zoneID: zone?.zoneID)
			var recordIDs: [CKRecord.ID] = []

			for try await record in seq {
				recordIDs.append(record.recordID)
			}
			
			results.ids[recordType] = recordIDs
		}
		return results
	}

	public func deleteAll(from recordTypes: [CKRecord.RecordType], in zone: CKRecordZone? = nil) async throws {
		if await Cirrus.instance.isOffline { throw Cirrus.CirrusError.offline }
		let ids = try await allRecordIDs(from: recordTypes, in: zone)
		let chunkSize = 30
		let idChunks = ids.all.breakIntoChunks(ofSize: chunkSize)
		
		for chunk in idChunks {
			do {
				let deleted = try await delete(recordIDs: chunk)
				if deleted.count != chunk.count {
					logg("Failed to delete some records (attempted \(chunk.count), succeeded on \(deleted.count).")
				}
			} catch {
				logg(error: error, "Error when deleting")
			}
		}
		
		logg("Deleted \(ids.count) records")
	}
}


extension CKDatabase.Scope: Codable {
	public var database: CKDatabase {
		switch self {
		case .private: return Cirrus.instance.container.privateCloudDatabase
		case .public: return Cirrus.instance.container.publicCloudDatabase
		case .shared: return Cirrus.instance.container.sharedCloudDatabase
		default: return Cirrus.instance.container.privateCloudDatabase
		}
	}
	public static var allScopes: [CKDatabase.Scope] {
		[.private, .public, .shared]
	}
	
	public var name: String {
		switch self {
		case .private: return "private"
		case .public: return "public"
		case .shared: return "shared"
		default: return "\(rawValue)"
		}
	}
}
