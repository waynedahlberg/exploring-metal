//
//  curtain.metal
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/12/24.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[ stitchable ]] half4 curtain(float2 position, SwiftUI::Layer layer, float4 bounds, float2 dragPosition, float foldCount) {
  // The `position` expressed in unit space [0,1]
  float2 uv = position / bounds.zw;
  
  // The `dragPosition` expressed in unit space [0,1]
  float2 dragUV = dragPosition / bounds.zw;
  
  // Reveal each row of pixels uniformly
  // 0: fully closed
  // 1: fully open
  // Matches distance of drag location to the left edge,
  // the location of the touch
  float uniformReveal = saturate(1 - dragUV.x);
  
  // Abort early if curtain = 1, full open
  if (uniformReveal == 1) return 0;
  
  // Reveal each row of pixels based on distance to the drag location
  float2 distance = uv - dragUV;
  float localReveal = uniformReveal * exp(-pow(distance.y, 2) / 0.45);
  
  // Blend between uniform and local values with bias curve
  float compression = mix(localReveal, uniformReveal, saturate(pow(uniformReveal + 0.15, 1.8)));
  
  // Scale `uv` horizontally based on `compression`
  float2 distortedUV = uv * float2(1 / (1 - compression), 1);
  
  // Create illusion of surface of curtain folding
  // A - move sample position vertically
  // B - Tweak sampled color to create illusion of light hitting folds
  float p = 1.0 / foldCount;
  
  // Bias fold toward right edge
  float biasedX = pow(distortedUV.x, 1.2);
  
  // Scale factor for lighting and vertical displacement
  float foldAmount = distortedUV.x * -(cos(compression * M_PI_F) - 1) / 2;
  
  // Model creases in curtain
  float fold = 2 * abs(biasedX / p - floor(biasedX / p + 0.5));
  float foldD = sign(sin(2 * M_PI_F * biasedX / p));
  
  // Displace y coords of sample location, scaled by distance to vertical center of layer
  distortedUV.y += foldAmount * fold * (-12 / bounds.w) * (2 * uv.y - 1);
  
  // The light we're adding and subtracting
  half4 highlight = 0;
  
  if (distortedUV.x < 1) {
    highlight += foldAmount * foldD * half4(half3(0.1), 0);
    highlight -= compression * half4(half3(0.1), 0);
  }
  
  // New sample position in coord space of 'layer'
  float2 s = distortedUV * bounds.zw;
  
  // Sample offsets of blur
  const float offset[5] = {0.0, 1.0, 2.0, 3.0, 4.0};
  
  // Weights of blur
  const float weight[5] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };
  
  half4 color = layer.sample(s);
  half4 blurred = color * weight[0];
  
  // perform blur
  for (int i; i < 5; i++) {
    blurred += layer.sample(s + float2(1, 0) * offset[i]) * weight[i];
    blurred += layer.sample(s - float2(1, 0) * offset[i]) * weight[i];
  }
  
  // mix, then add highlight
  return mix(color, blurred, 1.1 * pow(compression, 1.4)) + highlight;
  
}



