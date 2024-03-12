//
//  CountdownView.swift
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/12/24.
//

import SwiftUI

private let _previewLoadDate = Date.now

#Preview("Smash Countdown Timer") {
  SmashCounterView()
}

struct CountdownView: View {
  var date: Date
  init(date: Date) {
    self.date = date
  }
  
  var body: some View {
    VStack {
      Button("Increase count") {
        
      }
      .padding(16)
      .buttonStyle(.borderedProminent)
      CountdownLabelView(date: .now)
    }
  }
}

struct CountdownLabelView: View {
  // The date that we're counting down towards.
  var date: Date
  
  init(date: Date) {
    self.date = date
  }
  
  // To achieve the outline effect, we need to convert the individual
  // digits to shapes using `TextShape`.
  //
  // We also cache the underlying paths using `CachedShape` as there
  // are only a few possible characters and converting them is
  // comparatively expensive.
  static let shapes: [Character: some Shape] = {
    let characters: [Character] = [
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
    ]
    
    let font = UIFont
      .systemFont(ofSize: 75, weight: .semibold, width: .init(-0.36))
    
    let shapes = characters.map { character in
      CachedShape(TextShape(font: font, text: String(character)))
    }
    
    return Dictionary(uniqueKeysWithValues: zip(characters, shapes))
  }()
  
  let gradient = LinearGradient(
    colors: [.red, .pink, .yellow],
    startPoint: .top,
    endPoint: .bottom
  )
  
  // The spring that drives the bounce animation for each individual digit.
  let spring = Spring.bouncy(duration: 0.4, extraBounce: 0.2)
  
  // Calculates the vertical displacement of a digit at a given point in time.
  func displacement(duration: TimeInterval, exponent: Int) -> CGFloat {
    // Calculate the magnitude (hundreds, tens, ones) of the
    // current exponent.
    let magnitude = pow(10, Double(exponent))
    
    // Calculate how much time has passed since the last time the current
    // digit changed.
    //
    // For the ones place, this will wrap between 0 and 1.
    // For the tens place, this will wrap between 0 and 10.
    let t = magnitude - fmod(duration, magnitude)
    
    // Resolve the spring for the current time.
    return 60 * spring.value(target: 0, initialVelocity: -10, time: t)
  }
  
  var body: some View {
    TimelineView(.animation(paused: date < .now)) { context in
      // How much time is remaining.
      //
      // Since the entire animation is driven by this value, there is
      // no need to mess around with additional timers or transitions.
      let duration = max(0, date.timeIntervalSinceReferenceDate - context.date.timeIntervalSinceReferenceDate)
      
      // Format the remaining time, dropping fractional seconds.
      //
      // TODO: Make sure the current locale's numbering system is `latn`
      //       or cache appropriate glyphs for other locales.
      let text = duration.formatted(.number.grouping(.never).precision(.fractionLength(0)).rounded(rule: .down))
      
      // Pair every character with its exponent, e.g.:
      //
      // 42 -> 4 * 10^1 + 2 * 10^0 -> [("4", 1), ("2", 0))
      let characters = Array(zip(text, (0 ..< text.count).reversed()))
      
      // Layout the individual glyphs manually. This may not be
      // appropriate for all writing systems.
      HStack(spacing: 1) {
        ForEach(characters, id: \.1) { (c, exponent) in
          let shape = Self.shapes[c]!
          
          ZStack {
            shape
              .stroke(.black, lineWidth: 15)
            
            shape
              .fill(gradient)
              .brightness(0.2)
          }
          // Use a `.plusLighter` blend mode to have the bright fill
          // of one character overlay the darker stroke of another.
          .blendMode(.plusLighter)
          .offset(y: displacement(duration: duration, exponent: exponent))
        }
      }
      // For the label to point upward slightly, we apply a shear
      // transform. Unlike a rotation, this will keep vertical strokes
      // paralell with the screen.
      .transformEffect(CGAffineTransform(shearX: 0, y: -0.1))
      // Instead of calculating a new gradient, we can simply rotate the
      // hue of a fixed gradient through the rainbow.
      .hueRotation(.radians(duration * 4))
    }
    .compositingGroup()
  }
}

// MARK: - TextShape

struct TextShape: Shape, Equatable {
  var font: UIFont
  var text: AttributedString
  var options: CTLineBoundsOptions = [
    .useOpticalBounds
  ]
  
  init(font: UIFont, text: String) {
    self.init(font: font, text: AttributedString(text))
  }
  
  init(font: UIFont, text: AttributedString) {
    self.font = font
    self.text = text
    
    var container = AttributeContainer()
    container[AttributeScopes.UIKitAttributes.FontAttribute.self] = font
    
    self.text.mergeAttributes(container, mergePolicy: .keepNew)
  }
  
  func path(in rect: CGRect) -> Path {
    let attributedString = NSAttributedString(text)
    
    let typeSetter = CTTypesetterCreateWithAttributedString(attributedString)
    let line = CTTypesetterCreateLine(typeSetter, CFRangeMake(0, 0))
    let bounds = CTLineGetBoundsWithOptions(line, options)
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    
    let path = CGMutablePath()
    
    for run in runs {
      let count = CTRunGetGlyphCount(run)
      
      guard let glyphsPointer = CTRunGetGlyphsPtr(run) else {
        continue
      }
      
      let positions = CTRunGetPositionsPtr(run)
      
      var t = CGAffineTransform.identity
      t = t.scaledBy(x: 1, y: -1)
      t = t.translatedBy(x: 0, y: -bounds.maxY)
      t = t.translatedBy(x: -bounds.minX, y: 0)
      
      for i in 0 ..< count {
        guard let subpath = CTFontCreatePathForGlyph(font, glyphsPointer[i], nil) else {
          continue
        }
        
        let m = t.translatedBy(x: positions?[i].x ?? 0, y: 0)
        
        path.addPath(subpath.normalized(), transform: m)
      }
    }
    
    return Path(path)
  }
  
  func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
    let attributedString = NSAttributedString(text)
    
    let typeSetter = CTTypesetterCreateWithAttributedString(attributedString)
    let line = CTTypesetterCreateLine(typeSetter, CFRangeMake(0, 0))
    let bounds = CTLineGetBoundsWithOptions(line, options)
    
    return bounds.size
  }
}

#Preview("Text Shape") {
  TextShape(font: .boldSystemFont(ofSize: 32), text: "Hello")
    .stroke(.red)
    .border(.blue)
}

// MARK: - Cached Shape
struct CachedShape<S: Shape>: Shape, Equatable {
  var size: CGSize
  var path: Path
  
  init(_ shape: S, proposedSize: ProposedViewSize = ProposedViewSize(width: nil, height: nil)) {
    let size = shape.sizeThatFits(proposedSize)
    
    self.size = size
    self.path = shape.path(in: CGRect(origin: .zero, size: size))
  }
  
  func path(in rect: CGRect) -> Path {
    path
  }
  
  func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
    size
  }
}

// MARK: - Shear transform

extension CGAffineTransform {
  init(shearX x: CGFloat, y: CGFloat) {
    self = .identity
    self.c = x
    self.b = y
  }
}

#Preview("Shear") {
  ZStack {
    Rectangle()
      .fill(.blue.opacity(0.5))
      .frame(width: 100, height: 100)
      .transformEffect(CGAffineTransform(shearX: 0, y: -0.1))
    
    Rectangle()
      .fill(.red.opacity(0.5))
      .frame(width: 100, height: 100)
  }
}

struct SmashCounterView: View {
  var body: some View {
    VStack {
      CountdownView(date: .now + 36)
      
      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        colors: [.blue, .purple],
        startPoint: .top,
        endPoint: .bottom
      )
      .edgesIgnoringSafeArea(.all)
      .brightness(-0.1)
    )
  }
}
