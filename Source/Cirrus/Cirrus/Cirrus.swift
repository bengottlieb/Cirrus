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
	

	public var state: AuthenticationState = .notLoggedIn { didSet { objectWillChange.send() }}
	public var configuration: Configuration!

	public var container: CKContainer!
	public var zones: [String: CKRecordZone] = [:]
	public var defaultRecordZone: CKRecordZone?

	public func zone(named name: String) -> CKRecordZone? { zones[name] }
	public func zone(withID id: CKRecordZone.ID) -> CKRecordZone? { zones.values.first { $0.zoneID == id } }
	public var allZoneIDs: [CKRecordZone.ID] { zones.values.map { $0.zoneID } }
	
	internal var cancelBag = Set<AnyCancellable>()
	@FileBackedCodable(url: .library(named: "cirrus.local.dat"), initialValue: LocalState()) var localState
}

