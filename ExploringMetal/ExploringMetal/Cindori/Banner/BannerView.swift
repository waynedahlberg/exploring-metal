//
//  BannerView.swift
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/11/24.
//

import SwiftUI

struct BannerView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Introduction to Shaders in SwiftUI: Banner Effect")
        .fixedSize()
        .font(.title3.bold())
        .marquee(speed: 0.8, spacing: 48)
        .mask(LinearGradient(stops: [
          .init(color: .clear, location: 0.0),
          .init(color: .black, location: 0.15),
          .init(color: .black, location: 0.85),
          .init(color: .clear, location: 1.0)
        ], startPoint: .leading, endPoint: .trailing))
      
      Text("Learn Metal Shaders • 12 Min Read")
        .foregroundStyle(.secondary)
        .font(.body.bold())
        .padding(.horizontal, 24)
    }
    .foregroundStyle(.white)
    .padding(.vertical, 32)
    .background(.linearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom))
  }
}

#Preview {
  BannerView()
}
