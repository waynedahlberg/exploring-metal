//
//  Wave.metal
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/11/24.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] float2 wave(float2 position, float length, float amplitude, float time) {
    return position-float2(0, sin(time+position.x/length)*amplitude);
}

