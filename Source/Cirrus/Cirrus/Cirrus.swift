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

	public func zone(named name: String) -> CKRecordZone? {
		zones[name]
	}
	
	internal var cancelBag = Set<AnyCancellable>()
	@FileBackedCodable(url: .library(named: "cirrus.local.dat"), initialValue: LocalState()) var localState
}

