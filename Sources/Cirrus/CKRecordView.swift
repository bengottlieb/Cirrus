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
				VStack(alignment: .leading) {
					Labeled(label: "ID", content: record.recordID.recordName)
					Labeled(label: "Type", content: record.recordType)
					if let share = record.share {
						Labeled(label: "Sharing", content: "\(share)")
					}
					
					let keys = record.allKeys()
					
					ForEach(keys, id: \.self) { key in
						if let value = record[key] {
							Labeled(label: key, content: "\(value)")
						}
					}
					
					Spacer(minLength: 50)
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
	
	struct Labeled: View {
		let label: String
		let content: String
		
		var body: some View {
			HStack {
				Text(label)
				Text(content).bold()
			}
		}
	}
}
