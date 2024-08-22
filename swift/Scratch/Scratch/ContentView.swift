//
//  ContentView.swift
//  Scratch
//
//  Created by OD Orafidiya on 4/26/24.
//

import SwiftUI

struct ResultView: View {
    var choice: String
    
    var body: some View {
        Text("You chose some \(choice)")
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("You going to flip a coin. DO you want to choose heads or tails")
                NavigationLink(destination: ResultView(choice: "heads")) {
                    Text("Choose heads")
                }
                NavigationLink(destination: ResultView(choice: "tails")) {
                    Text("Choose Tails")
                }
            }
            .navigationBarTitle("Navigation")
        }
        
    }
}

#Preview {
    ContentView()
}
