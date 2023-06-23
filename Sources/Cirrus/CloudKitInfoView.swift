//
//  CloudKitInfoView.swift
//
//
//  Created by Ben Gottlieb on 6/19/23.
//

import SwiftUI
import CloudKit

extension CKRecord: Identifiable {
	public var id: ID { recordID }
}

@MainActor public struct CloudKitInfoView: View {
	@State private var databaseInfo: DatabaseInfo?
	@State private var cached: [CKDatabase.Kind: DatabaseInfo] = [:]
	@State private var currentDatabaseKind = CKDatabase.Kind.public
	@State private var pendingKind: CKDatabase.Kind? = .public
	@State private var error: Error?
	@State private var selectedSubscription: CKSubscription?
	@State var detailsRecord: CKRecord?
	let showRecordIDs: Bool
	let recordTypes: [CKRecord.RecordType]
	
	public init(recordTypes: [CKRecord.RecordType] = [], showRecordIDs: Bool = true) {
		self.recordTypes = recordTypes
		self.showRecordIDs = showRecordIDs
	}
	
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
					VStack(alignment: .leading, spacing: 5) {
						if case .authenticated(let id) = Cirrus.instance.state {
							Text("ID: \(id.recordName)")
						}
						
						Text("Records").frame(maxWidth: .infinity, alignment: .center).background(Color.black).foregroundColor(.white)
						ForEach(recordTypes, id: \.self) { type in
							if let ids = databaseInfo.recordIDs[type] {
								Text("\(type): \(ids.count)")
								if showRecordIDs {
									VStack(alignment: .leading) {
										ForEach(ids, id: \.recordName) { id in
											Text("\(id.recordName)")
												.font(.callout)
												.onTapGesture {
													Task {
														detailsRecord = try? await currentDatabaseKind.database.fetchRecord(withID: id)
													}
												}
										}
									}
								}
							}
						}
						
						Text("Zones").frame(maxWidth: .infinity, alignment: .center).background(Color.black).foregroundColor(.white)
						ForEach(databaseInfo.zones, id: \.zoneID) { zone in
							VStack(alignment: .leading) {
								Text(zone.zoneID.zoneName)
									.font(.headline)
								Text(zone.zoneID.description)
									.font(.caption)
							}
						}

						Text("Subscriptions").frame(maxWidth: .infinity, alignment: .center).background(Color.black).foregroundColor(.white)
						ForEach(databaseInfo.subscriptions, id: \.subscriptionID) { sub in
							VStack(alignment: .leading) {
								Text(sub.subscriptionID.description)
									.font(.headline)
								Text(sub.detailedDescription)
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
							.onTapGesture { selectedSubscription = sub }
						}
					}
					.padding()
				}
			}
		}
		.onChange(of: currentDatabaseKind) { kind in load(kind) }
		.sheet(item: $detailsRecord) { record in
			CKRecordView(record: record, database: currentDatabaseKind.database)
		}
		.alert("Delete Subscription", isPresented: .constant(selectedSubscription != nil), presenting: $selectedSubscription, actions: { sub in
			Button("Delete Subscription", role: .destructive) { deleteSubscription(sub.wrappedValue) }
		}, message: { _ in
			Text("Are you sure?")
			Text("This cannot be undone.")
		})
		.onAppear { load(.public) }
	}
	
	func deleteSubscription(_ sub: CKSubscription?) {
		guard let sub else { return }
		Task {
			do {
				try await currentDatabaseKind.database.deleteSubscription(withID: sub.subscriptionID)
				reload()
			} catch {
				self.error = error
			}
		}
	}
	
	func reload() {
		cached[currentDatabaseKind] = nil
		load(currentDatabaseKind)
	}
	
	func load(_ kind: CKDatabase.Kind) {
		self.error = nil
		if let cached = cached[kind] {
			databaseInfo = cached
			return
		}
		pendingKind = kind
		Task {
			do {
				databaseInfo = try await DatabaseInfo.info(for: kind, recordTypes: recordTypes)
				cached[kind] = databaseInfo
			} catch {
				self.error = error
			}
			pendingKind = nil
		}
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
	var recordIDs: [CKRecord.RecordType: [CKRecord.ID]] = [:]
	
	static func info(for kind: CKDatabase.Kind, recordTypes: [CKRecord.RecordType]) async throws -> DatabaseInfo {
		var info = DatabaseInfo()
		
		info.zones = try await kind.database.allRecordZones()
		info.subscriptions = try await kind.database.allSubscriptions()
		
		for type in recordTypes {
			var recordIDs: [CKRecord.ID] = []
			if kind == .shared {
				for zone in info.zones {
					recordIDs += try await kind.database.allRecordIDs(from: [type], in: zone).ids[type] ?? []
				}
			} else {
				recordIDs += try await kind.database.allRecordIDs(from: [type]).ids[type] ?? []
			}
			info.recordIDs[type] = recordIDs
		}
		
		return info
	}
}
