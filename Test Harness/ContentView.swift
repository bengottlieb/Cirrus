//
//  ContentView.swift
//  Cirrus
//
//  Created by Ben Gottlieb on 7/16/21.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var cirrus = Cirrus.instance
	@State var previousUserID: String?
	
	var body: some View {
		VStack() {
			if let prev = previousUserID {
				Text("Was signed in as: \(prev)")
			}
			
			if case .authenticated(let id) = cirrus.state {
				Text("Signed in as: \(id.recordName)")
			}

			switch cirrus.state {
			case .authenticated:
				Text("Welcome!")
				
			case .signingIn:
				ProgressView()
				
			case .denied, .tokenFailed, .notLoggedIn:
				Button("Please Sign In!") {
					Cirrus.launchCloudSettings()
				}
				
			case .failed(let error):
				Text(error.localizedDescription)
					.foregroundColor(Color.red)
					.font(.caption)
					.padding()
					.multilineTextAlignment(.center)
			}
			
		}
		.onReceive(Cirrus.Notifications.currentUserChanged.publisher()) { note in
			previousUserID = note.object as? String ?? "None"
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
