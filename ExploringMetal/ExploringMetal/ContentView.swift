//
//  ContentView.swift
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/11/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
      NavigationStack {
        List {
          NavigationLink(destination: PatternView()) {
            Text("Patterns")
          }
          NavigationLink(destination: BannerView()) {
            Text("Banner")
          }
          NavigationLink(destination: WaveView()) {
            Text("Wave")
          }
          NavigationLink(destination: CurtainView()) {
            Text("Curtain")
          }
          NavigationLink(destination: SmashCounterView()) {
            Text("Countdown")
          }
        }
        .navigationTitle("Exploring Metal")
        .listStyle(.plain)
      }
    }
}

#Preview {
    ContentView()
}
