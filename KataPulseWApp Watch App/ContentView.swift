//
//  ContentView.swift
//  KataPulseWApp Watch App
//
//  Created by Aaron Addleman on 10/27/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Training Session")
                .font(.headline)
                .padding()

            Button("Next Move") {
                // Send the "nextMove" command to the iPhone
                WatchManager.shared.sendMessageToiPhone(["command": "nextMove"])
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
