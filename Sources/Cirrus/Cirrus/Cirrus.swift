//
//  Cirrus.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit


public class Cirrus: ObservableObject {
	public static let instance = Cirrus()
	
	public var mutability: Mutability = .normal
	public var state: AuthenticationState = .notLoggedIn { didSet { objectWillChange.sendOnMain() }}
	public var cloudQuotaExceeded = false { didSet { objectWillChange.sendOnMain() }}
	public var configuration: Configuration!
	
	public var container: CKContainer!
	public var sharedZones: [CKRecordZone] = []
	public var privateZones: [String: CKRecordZone] = [:]
	public var defaultPrivateZone: CKRecordZone?

	public func privateZone(named name: String) -> CKRecordZone? {
		privateZones[name]
	}

	public func zone(withID id: CKRecordZone.ID, in scope: CKDatabase.Scope) -> CKRecordZone? {
		switch scope {
		case .private: return privateZones.values.first { $0.zoneID == id }
		case .shared: return sharedZones.first { $0.zoneID == id }
		default: return nil
		}
	}

	public func allZoneIDs(in scope: CKDatabase.Scope) -> [CKRecordZone.ID] {
		switch scope {
		case .private: return privateZones.values.map { $0.zoneID }
		case .shared: return sharedZones.map { $0.zoneID }
		default: return []
		}
	}
	
	internal var cancelBag = Set<AnyCancellable>()
	@FileBackedCodable(url: .library(named: "cirrus.local.dat"), initialValue: LocalState()) var localState
}

public extension Cirrus {
	struct MutabilityError: Error, LocalizedError {
		let localizedDescription: String
		init(_ desc: String) {
			localizedDescription = desc
		}
	}
	
	enum Mutability: Int { case normal, readOnlyCloud, readOnly
		public var isReadOnlyForCloudOps: Bool { return self != .normal }
		public var isReadOnlyForCoreData: Bool { return self == .readOnly }
	}
}
