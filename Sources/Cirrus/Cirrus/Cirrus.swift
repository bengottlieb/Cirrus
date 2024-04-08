//
//  Cirrus.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit
import Combine

public class Cirrus: ObservableObject {
	public static let instance = Cirrus()
	
	public var mutability: Mutability = .normal
	public var state: AuthenticationState = .notLoggedIn { didSet {
		objectWillChange.sendOnMain()
		if state != oldValue { currentState.send(state) }
	}}
	public var cloudQuotaExceeded = false { didSet { objectWillChange.sendOnMain() }}
	public var configuration: Configuration!
	
	public var container: CKContainer!
	public var sharedZones: [CKRecordZone] = []
	public var privateZones: [String: CKRecordZone] = [:]
	public var defaultPrivateZone: CKRecordZone?
	public var autoCreateNewZones = true
	public var privateZoneIDs: [CKRecordZone.ID] { Array(privateZones.values.map { $0.zoneID })}
	public var sharedZoneIDs: [CKRecordZone.ID] { Array(sharedZones.map { $0.zoneID })}
	
	public var isConfigured: Bool { configuration != nil }
	public var isOffline: Bool { if case .offline = state { return true } else { return false }}
	public var currentState: CurrentValueSubject<AuthenticationState, Never> = .init(.notLoggedIn)

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
	@CodableFileStorage(.library(named: "cirrus.local.dat")) var localState = LocalState()
	
	@MainActor func reachabilityChanged() {
		if Reachability.instance.isOffline {
			if case let .authenticated(id) = state {
				state = .offline(id)
			}
		} else {
			if case let .offline(id) = state {
				state = .authenticated(id)
			}
		}
	}
	
	init() {
		Task { @MainActor in
			Reachability.instance.setup()
			Reachability.Notifications.reachabilityChanged.publisher()
				.sink { _ in
					self.reachabilityChanged()
				}
				.store(in: &cancelBag)
		}
	}
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
