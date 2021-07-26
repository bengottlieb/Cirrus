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
		NavigationView() {
			VStack() {
				switch cirrus.state {
				case .offline,  .authenticated:
					EmojiListView()
					
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
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
