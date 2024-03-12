//
//  CurtainView.swift
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/12/24.
//

import SwiftUI

struct CurtainStack<Foreground: View, Background: View>: View, Animatable {
  // Position of current drag operation, or `nil`
  @State private var dragPosition: CGPoint?
  
  // `true` if bottom layer is revealed
  @State private var isRevealed: Bool = false
  
  var foreground: Foreground
  var background: Background
  
  // Number of folds in curtain
  var folds: Int
  
  init(folds: Int = 4, @ViewBuilder foreground: () -> Foreground, @ViewBuilder background: () -> Background) {
    self.folds = folds
    self.foreground = foreground()
    self.background = background()
  }
  
  var body: some View {
    GeometryReader { geometry in
      let maxX = geometry.size.width
      
      // simple drag gesture, track location in explicit coord space
      let drag = DragGesture(minimumDistance: 0, coordinateSpace: .named("curtain"))
        .onChanged { v in
          withAnimation(.interactiveSpring) {
            var position = v.location
            position.x = rubberClamp(44, position.x, 1_000_000)
            dragPosition = position
          }
        }
        .onEnded { v in
          if v.predictedEndLocation.x < 100 {
            isRevealed = true
            
            withAnimation {
              dragPosition?.x = 44
            }
          } else {
            isRevealed = false
            
            withAnimation {
              dragPosition?.x = maxX
            }
          }
        }
      
      ZStack {
        background
          .safeAreaPadding(EdgeInsets(top: 0, leading: 44, bottom: 0, trailing: 0))
        
        foreground
          .modifier(CurtainEffect(
            foldCount: folds,
            dragPosition: dragPosition ?? CGPoint(x: maxX, y: 0), maxX: maxX
          ))
          .allowsHitTesting(!isRevealed)
          .accessibilityHidden(isRevealed)
          .shadow(radius: isRevealed ? 10 : 0)
      }
      .overlay(alignment: isRevealed ? .leading : .trailing) {
        Color.clear
          .contentShape(Rectangle())
          .frame(width: 44)
          .gesture(drag)
      }
      .coordinateSpace(.named("curtain"))
    }
  }
}

struct CurtainEffect: ViewModifier, Animatable {
  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get {
      AnimatableData(dragPosition.x, dragPosition.y)
    }
    set {
      dragPosition.x = newValue.first
      dragPosition.y = newValue.second
    }
  }
  
  // Location of drag in coord space of `content`
  var dragPosition: CGPoint
  var maxX: CGFloat
  var foldCount: Int
  
  let shaderFunction = ShaderFunction(library: .default, name: "curtain")
  
  init(foldCount: Int = 4, dragPosition: CGPoint, maxX: CGFloat) {
    self.foldCount = foldCount
    self.dragPosition = dragPosition
    self.maxX = maxX
  }
  
  func body(content: Content) -> some View {
    let shader = Shader(function: shaderFunction, arguments: [
      .boundingRect,
      .float2(max(20, animatableData.first), animatableData.second),
      .float(Float(foldCount))
    ])
    
    let isEnabled = dragPosition.x != maxX
    
    content
      .visualEffect { content, geometryProxy in
        content
          .layerEffect(
            shader, maxSampleOffset: CGSize(width: geometryProxy.size.width, height: 20), isEnabled: isEnabled)
      }
  }
}

struct CurtainView: View {
  var body: some View {
    CurtainExample()
  }
}

#Preview {
  CurtainView()
}

struct CurtainExample: View {
  enum Foreground: String {
    case text
    case grid
  }
  
  @State
  var foldCount: Int = 4
  
  @State
  var foreground: Foreground = .text
  
  @State
  var date = Date.now
  
  var body: some View {
    CurtainStack(folds: foldCount) {
      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading) {
          Text("SwiftUI Snippets").font(.caption.weight(.medium))
            .textCase(.uppercase).tracking(0.2)
            .foregroundStyle(.secondary)
          
          Text("Curtain Effect").font(.title.weight(.semibold))
            .padding(.bottom)
        }
        
        Text("""
                This effect uses a SwiftUI `Shader` in combination with a `DragGesture` to create a curtain effect that deforms the view in response to the drag location.
                """)
        
        HStack(alignment: .firstTextBaseline) {
          Image(systemName: "hand.point.up.left").imageScale(.large)
          
          Text("Try swiping from the right!")
            .fontWeight(.semibold)
        }
        
        Text("Because this approach does not rely on snapshotting, the contents of the foreground layer remain live.")
        
        Text("For example, this timer continues to update: ") + Text(date, style: .timer)
        
        Text("However, some caveats still apply:")
        
        Text("Views backed by UIKit will not display correctly on the top layer, this includes `List` but also `ProgressView`. Instead, the will render like this:")
        
        ProgressView()
        
        Text("More importantly, `ScrollView` also doesn't seem to work, limiting how much content you can fit on the screen.")
        
        Spacer()
      }
      .font(.body.leading(.loose))
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(white: 0.96))
      .colorScheme(.light)
    } background: {
      List {
        Section {
          Stepper("Number of Folds (\(foldCount))", value: $foldCount, in: 1 ... 8)
        } header: {
          Text("Settings")
        } footer: {
          Text("The backdrop view is not affected by the `Shaders`'s limitations and may use e.g. `List` freely.")
        }
      }
      .colorScheme(.dark)
    }
  }
}

private func clamp(_ min: CGFloat, _ value: CGFloat, _ max: CGFloat) -> CGFloat {
  Swift.max(min, Swift.min(value, max))
}

private func rubberClamp(_ min: CGFloat, _ value: CGFloat, _ max: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
  let clamped = clamp(min, value, max)
  
  let delta = abs(clamped - value)
  
  guard delta != 0 else {
    return value
  }
  
  let sign: CGFloat = clamped > value ? -1 : 1
  
  let range = (max - min)
  
  return clamped + sign * (1.0 - (1.0 / ((delta * coefficient / range) + 1.0))) * range
}

extension Shader.Argument {
  static func float2(_ unitPoint: UnitPoint) -> Self {
    self.float2(unitPoint.x, unitPoint.y)
  }
}
