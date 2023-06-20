//
//  CloudKitInfoView.swift
//
//
//  Created by Ben Gottlieb on 6/19/23.
//

import SwiftUI
import CloudKit

public struct CloudKitInfoView: View {
	@State private var databaseInfo: DatabaseInfo?
	@State private var cached: [CKDatabase.Kind: DatabaseInfo] = [:]
	@State private var currentDatabaseKind = CKDatabase.Kind.public
	@State private var pendingKind: CKDatabase.Kind? = .public
	@State private var error: Error?
	public init() { }
	
	public var body: some View {
		VStack {
			kindPicker.padding()
			ScrollView {
				if let error {
					Text(error.localizedDescription)
				} else if let pendingKind {
					Text("Loading \(pendingKind.rawValue)")
					ProgressView()
				} else if let databaseInfo {
					VStack(alignment: .leading) {
						if case .authenticated(let id) = Cirrus.instance.state {
							Text("ID: \(id.recordName)")
						}
						
						ForEach(databaseInfo.zones, id: \.zoneID) { zone in
							Text(zone.zoneID.zoneName)
								.font(.headline)
							Text(zone.zoneID.description)
								.font(.caption)
						}

						ForEach(databaseInfo.subscriptions, id: \.subscriptionID) { sub in
							Text(sub.subscriptionID.description)
								.font(.headline)
							Text(sub.subscriptionType.title)
								.font(.caption)
							if let querySub = sub as? CKQuerySubscription {
								HStack {
									if querySub.querySubscriptionOptions.contains(.firesOnce) { Text("once") }
									if querySub.querySubscriptionOptions.contains(.firesOnRecordCreation) { Text("create") }
									if querySub.querySubscriptionOptions.contains(.firesOnRecordUpdate) { Text("update") }
									if querySub.querySubscriptionOptions.contains(.firesOnRecordDeletion) { Text("deletion") }
								}
								.font(.caption)
							}
						}
					}
				}
			}
		}
		.onChange(of: currentDatabaseKind) { kind in load(kind) }
		.onAppear { load(.public) }
	}
	
	func load(_ kind: CKDatabase.Kind) {
		if let cached = cached[kind] {
			databaseInfo = cached
			return
		}
		pendingKind = kind
		Task {
			do {
				databaseInfo = try await DatabaseInfo.info(for: kind)
				cached[kind] = databaseInfo
			} catch {
				self.error = error
			}
		}
		pendingKind = nil
	}
}

extension CloudKitInfoView {
	@ViewBuilder var kindPicker: some View {
		Picker("Kind", selection: $currentDatabaseKind) {
			Text("Public").tag(CKDatabase.Kind.public)
			Text("Private").tag(CKDatabase.Kind.private)
			Text("Shared").tag(CKDatabase.Kind.shared)
		}
		.pickerStyle(.segmented)
	}
}



struct DatabaseInfo {
	var zones: [CKRecordZone] = []
	var subscriptions: [CKSubscription] = []
	
	static func info(for kind: CKDatabase.Kind) async throws -> DatabaseInfo {
		var info = DatabaseInfo()
		
		info.zones = try await kind.database.allRecordZones()
		info.subscriptions = try await kind.database.allSubscriptions()
		
		return info
	}
}
