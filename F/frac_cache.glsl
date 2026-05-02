#version 330 core

out vec4 color;
in vec2 tc;

// Texture samplers
uniform sampler2D samp;  // Base texture
uniform sampler2D samp1; // Texture #1
uniform sampler2D samp2; // Texture #2
uniform sampler2D samp3; // Texture #3
uniform sampler2D samp4; // Texture #4

// External uniforms
uniform vec2 iResolution; // Resolution of the viewport/window
uniform float time_f;     // Time in seconds

//------------------------------------------------------//
// Helper: 2D rotation
//------------------------------------------------------//
vec2 rotate2D(vec2 p, float angle) {
    mat2 r = mat2(cos(angle), -sin(angle),
                  sin(angle), cos(angle));
    return r * p;
}

//------------------------------------------------------//
// Helper: Simple fractal iteration (Julia-like)
//------------------------------------------------------//
float fractalJulia(vec2 z, vec2 c, int iterations) {
    float m = 0.0;
    for (int i = 0; i < iterations; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (dot(z, z) > 4.0) {
            m = float(i) / float(iterations);
            break;
        }
    }
    return m;
}

//------------------------------------------------------//
// Helper: A basic swirl distortion
//------------------------------------------------------//
vec2 swirl(vec2 uv, vec2 center, float radius, float strength) {
    float dist = distance(uv, center);
    if (dist < radius) {
        float percent = (radius - dist) / radius;
        float theta = percent * percent * strength;
        vec2 dir = uv - center;
        dir = rotate2D(dir, theta);
        uv = dir + center;
    }
    return uv;
}

//------------------------------------------------------//
// Helper: Kaleidoscopic reflection
//------------------------------------------------------//
vec2 kaleidoscope(vec2 p, float slices) {
    // Angle for each slice
    float angle = 2.0 * 3.1415926535 / slices;
    // Convert to polar
    float r = length(p);
    float a = atan(p.y, p.x);
    // Mirror that angle around slice boundaries
    a = mod(a, angle);
    // Convert back to Cartesian
    return vec2(r * cos(a), r * sin(a));
}

//------------------------------------------------------//
// MAIN
//------------------------------------------------------//
void main(void) {
    // Normalize uv so that (0,0) is at the screen center
    // This often helps with fractals and radial transformations
    vec2 uv = 2.0 * (tc - 0.5);

    //--------------------------------------------------//
    // 1. Texture #1: Apply swirl + rotation
    //--------------------------------------------------//
    {
        // Swirl around the center
        vec2 swirlUV = swirl(uv, vec2(0.0), 1.0, sin(time_f) * 5.0);
        // A slow rotation based on time
        swirlUV = rotate2D(swirlUV, time_f * 0.2);
        // Remap swirlUV back to [0..1]
        swirlUV = swirlUV * 0.5 + 0.5;

        // Sample from samp1 with the new swirl-based coords
        vec4 col1 = texture(samp1, swirlUV);

        // Multiply color by a factor to highlight
        col1 *= 1.2;

        // We’ll store it for blending later
        // Let’s name it colorSwirl
        // (We’ll sum up various results from the other steps below)
        vec4 colorSwirl = col1;

        // We can keep this in a temporary if we want to combine everything at the end
        // For now, let's declare a local here and combine at the end
        // We'll pass colorSwirl out into the final blend
    }

    //--------------------------------------------------//
    // 2. Texture #2: A fractal-based transformation
    //--------------------------------------------------//
    vec4 colorFractal2;
    {
        // For fractal: We'll compute a fractal function and use it as offset
        vec2 fractalUV = uv * 2.5; // Zoom factor
        // Animate using time
        float fractVal = fractalJulia(fractalUV,
                                      vec2(sin(time_f * 0.3) * 0.5, cos(time_f * 0.4) * 0.5),
                                      16);
        // Use fractVal to modulate sampling coordinates
        // E.g., add fractVal to both x, y
        vec2 newUV = (uv + fractVal * 0.3) * 0.5 + 0.5;
        // Sample from samp2
        colorFractal2 = texture(samp2, newUV);
        // Let’s give it some color shift or color highlight
        colorFractal2.rgb = mix(colorFractal2.rgb, vec3(fractVal, fractVal * 0.7, fractVal * 0.4), 0.5);
    }

    //--------------------------------------------------//
    // 3. Texture #3: Kaleidoscopic reflection
    //--------------------------------------------------//
    vec4 colorKaleido3;
    {
        // Let’s do a kaleidoscope effect with 6 slices
        vec2 kaleidoUV = kaleidoscope(uv, 6.0);
        // Possibly rotate for fun
        kaleidoUV = rotate2D(kaleidoUV, time_f * 0.5);
        // Then scale it in/out
        kaleidoUV *= (0.8 + sin(time_f * 0.7) * 0.2);
        // Remap to [0..1]
        kaleidoUV = kaleidoUV * 0.5 + 0.5;

        colorKaleido3 = texture(samp3, kaleidoUV);
        // Boost saturation
        colorKaleido3.rgb = colorKaleido3.rgb * 1.3;
    }

    //--------------------------------------------------//
    // 4. Texture #4: Another fractal or swirl variation
    //--------------------------------------------------//
    vec4 colorFractal4;
    {
        // Let’s combine swirl + fractal for texture #4
        vec2 swirl4UV = swirl(uv, vec2(0.0), 1.0, -sin(time_f * 0.5) * 3.0);
        swirl4UV = rotate2D(swirl4UV, time_f * 0.3);

        // Use swirl coords as input to fractal
        float fractVal2 = fractalJulia(swirl4UV * 2.0, vec2(0.3, 0.5), 12);
        swirl4UV += fractVal2 * 0.1;
        swirl4UV = swirl4UV * 0.5 + 0.5;

        // Sample the texture
        colorFractal4 = texture(samp4, swirl4UV);
        // Darken or lighten based on fractVal2
        colorFractal4.rgb *= mix(0.5, 1.5, fractVal2);
    }

    //--------------------------------------------------//
    // 5. Base texture (samp)
    //--------------------------------------------------//
    vec4 baseColor = texture(samp, tc);
    // Possibly do something subtle with the base
    // e.g., shift hue based on time
    float hueShift = sin(time_f * 0.3) * 0.2;
    // A cheap approximate hue rotation:
    // Convert to "YIQ" or do a small rotation in the R-G plane
    mat3 hueRotation = mat3(
        1.0, 0.0, 0.0,
        0.0, cos(hueShift), -sin(hueShift),
        0.0, sin(hueShift), cos(hueShift));
    baseColor.rgb = hueRotation * baseColor.rgb;

    //--------------------------------------------------//
    // Combine all
    //--------------------------------------------------//
    // Let's name them individually for clarity again:
    vec4 colorSwirl = texture(samp1, swirl(uv, vec2(0.0), 1.0, sin(time_f) * 5.0) * 0.5 + 0.5);
    vec4 colorFractal2F = colorFractal2;
    vec4 colorKaleido3F = colorKaleido3;
    vec4 colorFractal4F = colorFractal4;

    // Weighted combination - feel free to tweak
    // Just as an example:
    vec4 combo =
        0.25 * colorSwirl +
        0.25 * colorFractal2F +
        0.25 * colorKaleido3F +
        0.25 * colorFractal4F;

    // Mix the combo with the base texture
    // Maybe we do a simple additive blend with the base
    vec4 finalColor = mix(baseColor, combo, 0.7);

    // Output final
    color = finalColor;
}
