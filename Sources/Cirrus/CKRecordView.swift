//
//  CKRecordView.swift
//
//
//  Created by Ben Gottlieb on 6/22/23.
//

import SwiftUI
import CloudKit
import Suite

public struct CKRecordView: View {
	let record: CKRecord
	let database: CKDatabase?
	
	@State private var error: Error?
	
	public init(record: CKRecord, database: CKDatabase?) {
		self.record = record
		self.database = database
	}
	
	public var body: some View {
		VStack {
			if let error {
				Text(error.localizedDescription)
					.foregroundColor(.red)
					.padding()
			}
			ScrollView {
				VStack {
					Text("\(record)")
						.multilineTextAlignment(.leading)
				}
				.padding()
			}
			Spacer()
			if let database {
				AsyncButton("Delete Record", role: .destructive) {
					do {
						try await database.delete(record: record)
					} catch {
						self.error = error
					}
				}
			}
		}
		.buttonStyle(.borderedProminent)
		.padding()
	}
}
