//
//  BannerViewModifier.swift
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/11/24.
//

import SwiftUI

fileprivate struct MarqueeViewModifier: ViewModifier {
  var speed: CGFloat
  var spacing: CGFloat
  
  @State var size: CGSize = .zero
  
  let startDate = Date.now
  
  func body(content: Content) -> some View {
    if speed == 0 {
      effect(content: content, time: 0)
    } else {
      TimelineView(.animation) { context in
        effect(content: content, time: context.date.timeIntervalSince(startDate)*speed)
      }
    }
  }
  
  func effect(content: Content, time: CGFloat) -> some View {
    Color.clear
      .overlay {
        HStack(spacing: 0) {
          content
            .background {
              GeometryReader { geometry in
                Color.clear
                  .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds) { geometry[$0] }
              }
            }
            .onPreferenceChange(BoundsPreferenceKey.self) { size = $0.size }
          
          Rectangle()
            .frame(height: 1)
            .opacity(0.01)
        }
        .compositingGroup()
        .distortionEffect(ShaderLibrary.marquee(.float(time), .float(size.width+spacing)), maxSampleOffset: .zero)
      }
      .frame(height: size.height)
  }
}

fileprivate struct BoundsPreferenceKey: PreferenceKey {
  static var defaultValue: CGRect = .zero
  
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}

// View extension
extension View {
  func marquee(speed: CGFloat = 1, spacing: CGFloat = 12) -> some View {
    modifier(MarqueeViewModifier(speed: speed, spacing: spacing))
  }
}



// MARK: - Notes
// Notice how we're using a GeometryReader within a background modifier – that's because in SwiftUI, both backgrounds and overlays are applied after the view is computed – so they inherit their bounds but don't affect their layout.

