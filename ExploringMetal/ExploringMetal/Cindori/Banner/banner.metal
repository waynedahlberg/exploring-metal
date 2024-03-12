//
//  banner.metal
//  ExploringMetal
//
//  Created by Wayne Dahlberg on 3/11/24.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[ stitchable ]] float2 marquee(float2 position, float time, float phase) {
    float x = fmod(position.x+time*50, phase);
    if (x < 0) {
        x+= phase;
    }
    return float2(x, position.y);
}

// `fmod()` function is a modulo function takes an x and y and is defined by `x - y * trunc(x/y)` and returns a floating point remainder of `x/y`.Its value never exceeds `y` in magnitude. The sign of the result is the same as the sign of the dividend `x`.

// Learn more about `fmod()` here: https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
