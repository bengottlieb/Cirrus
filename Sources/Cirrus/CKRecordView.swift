//
//  CKRecordView.swift
//
//
//  Created by Ben Gottlieb on 6/22/23.
//

import SwiftUI
import CloudKit

public struct CKRecordView: View {
	let record: CKRecord
	
	public init(record: CKRecord) {
		self.record = record
	}
	
	public var body: some View {
		ScrollView {
			VStack {
				Text("\(record)")
					.multilineTextAlignment(.leading)
			}
			.padding()
		}
	}
}
