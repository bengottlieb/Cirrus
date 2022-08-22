//
//  CirrusStatusView.swift
//  
//
//  Created by Ben Gottlieb on 11/25/21.
//

#if os(iOS)
import SwiftUI

@available(iOSApplicationExtension, unavailable)
public struct CirrusStatusView<Content: View>: View {
    let content: () -> Content
    @ObservedObject var cirrus = Cirrus.instance
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        switch cirrus.state {
        case .offline, .authenticated:
            content()
        
        case .temporaryUnavailable:
            Text("Temporarily Unavailable.")
                .opacity(0.5)
			  Button("Please Sign In!") {
					Cirrus.launchCloudSettings()
			  }

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

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        CirrusStatusView() { Text("Signed In") }
    }
}
#endif
