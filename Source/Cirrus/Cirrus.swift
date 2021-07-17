//
//  Cirrus.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import Suite
import CloudKit


@MainActor
public class Cirrus: ObservableObject {
	public static let instance = Cirrus()
	

	public var state: AuthenticationState = .notLoggedIn { didSet { objectWillChange.send() }}
	public var configuration: Configuration!

	public var container: CKContainer!
	
	internal var cancelBag = Set<AnyCancellable>()
}

