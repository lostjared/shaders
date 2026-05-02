#version 330 core

in vec2 tc;
out vec4 color;

// Uniforms
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

// --------------------------------------------------------
// Pseudo-random helper: returns a float in [0..1]
// (Classic 2D hash based on UV coords)
float hash12(vec2 p) {
    // A simple hashing function
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// --------------------------------------------------------
// Generate a random seed for location (x,y) or fractal c
// based on some “key” (cycle index, etc.)
// --------------------------------------------------------
vec2 genSeed(float key) {
    // We’ll just return a pair of pseudo-random numbers:
    float r1 = hash12(vec2(key, 13.789));
    float r2 = hash12(vec2(key, 37.239));
    return vec2(r1, r2);
}

// --------------------------------------------------------
// Simple helper to rotate 2D coordinates
// --------------------------------------------------------
mat2 rotate2D(float angle) {
    return mat2(cos(angle), -sin(angle),
                sin(angle), cos(angle));
}

// --------------------------------------------------------
// Draw a Julia fractal around `center` using a “seed” c
// Returns a color with alpha determining intensity
// --------------------------------------------------------
vec4 drawJulia(vec2 uv, vec2 center, vec2 c) {
    // Let’s define how “large” the fractal area is
    // We'll zoom in around center
    float zoom = 2.0;
    uv = (uv - center) * zoom;

    // Iteration
    const int MAX_ITER = 30;
    vec2 z = uv;
    float m = 0.0;
    for (int i = 0; i < MAX_ITER; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (dot(z, z) > 4.0) {
            m = float(i) / float(MAX_ITER);
            break;
        }
    }

    // Convert iteration ratio into color
    float colVal = m;
    vec3 col = vec3(sin(colVal * 6.2831), // some fun banding
                    colVal,
                    1.0 - colVal);
    // Return with alpha = min(1.0, some factor)
    return vec4(col, smoothstep(0.0, 1.0, m));
}

// --------------------------------------------------------
// Draw another shape: e.g. a pulsating circle
// center, radius, etc. For variety.
// --------------------------------------------------------
vec4 drawPulsingCircle(vec2 uv, vec2 center, float radius) {
    // Distance from center
    float dist = length(uv - center);
    // Pulsate the radius with time
    float pulse = 0.5 + 0.4 * sin(time_f * 2.0);
    float finalRadius = radius * pulse;

    // Hard edge circle with smooth fade
    float edge = smoothstep(finalRadius, finalRadius - 0.01, dist);

    // We can color it however we like
    // Let’s do a gradient from center to edge
    float t = dist / finalRadius;
    vec3 baseColor = mix(vec3(1.0, 0.5, 0.0), // center color
                         vec3(0.0, 0.5, 1.0), // edge color
                         t);
    // edge is basically alpha for “outside vs inside”
    // invert because smoothstep finalRadius -> finalRadius-0.01
    float alpha = 1.0 - edge;

    return vec4(baseColor, alpha);
}

// --------------------------------------------------------
// main()
// We orchestrate time-based cycle here:
//   1) Draw fractal, fade in/out
//   2) Once done, draw circle in another random location
//   3) Repeat
// --------------------------------------------------------
void main(void) {
    //-----------------------------------------
    // 1) Basic pass-through from the original
    //    texture, so we have a background
    //-----------------------------------------
    color = texture(samp, tc);

    //-----------------------------------------
    // 2) Define cycle timing
    //    For example, each cycle is 10 seconds:
    //      0..4   : fractal fade in (some fraction)
    //      4..7   : fractal at full alpha
    //      7..8   : fractal fade out
    //      8..9.5 : circle fade in
    //      9.5..12: circle at full alpha
    //      12..13 : circle fade out
    // Then repeat
    //-----------------------------------------
    float cycleDuration = 13.0;
    float cycleTime = mod(time_f, cycleDuration);
    float cycleIndex = floor(time_f / cycleDuration);
    // We’ll use cycleIndex as a “seed” for random picks

    // Times for fractal
    float fractalFadeInStart = 0.0;
    float fractalFadeInEnd = 1.0;  // 0..1
    float fractalHoldEnd = 3.0;    // 1..3
    float fractalFadeOutEnd = 4.0; // 3..4

    // Times for circle
    float circleFadeInStart = 5.0;
    float circleFadeInEnd = 6.0;  // 5..6
    float circleHoldEnd = 8.0;    // 6..8
    float circleFadeOutEnd = 9.0; // 8..9

    //-----------------------------------------
    // 3) Random seeds and positions
    //    We’ll pick:
    //       - fractal location, fractal “c”
    //       - circle location, circle radius
    //-----------------------------------------
    // fractal center (in clip space [-1..1])
    vec2 fractalRand = genSeed(cycleIndex * 3.17);
    // Map from [0..1] to [-0.8..0.8], so it's not off-screen
    vec2 fractalCenter = fractalRand * 1.6 - 0.8;
    // fractal c
    vec2 fractalSeed = genSeed(cycleIndex * 1.93) * 2.0 - 1.0;

    // circle center
    vec2 circleRand = genSeed(cycleIndex * 7.87 + 1.234);
    vec2 circleCenter = circleRand * 1.6 - 0.8;
    // circle radius
    float circleRadius = 0.2 + 0.2 * hash12(circleRand + 0.123);

    //-----------------------------------------
    // 4) Evaluate alpha for fractal in current
    //    time sub-interval
    //-----------------------------------------
    float fractalAlpha = 0.0;
    if (cycleTime >= fractalFadeInStart && cycleTime < fractalFadeInEnd) {
        // fade in from 0..1
        float t = (cycleTime - fractalFadeInStart) / (fractalFadeInEnd - fractalFadeInStart);
        fractalAlpha = smoothstep(0.0, 1.0, t);
    } else if (cycleTime >= fractalFadeInEnd && cycleTime < fractalHoldEnd) {
        // hold at 1
        fractalAlpha = 1.0;
    } else if (cycleTime >= fractalHoldEnd && cycleTime < fractalFadeOutEnd) {
        // fade out from 1..0
        float t = (cycleTime - fractalHoldEnd) / (fractalFadeOutEnd - fractalHoldEnd);
        fractalAlpha = 1.0 - smoothstep(0.0, 1.0, t);
    }
    // else fractalAlpha remains 0 outside that interval

    //-----------------------------------------
    // 5) Evaluate alpha for circle
    //-----------------------------------------
    float circleAlpha = 0.0;
    if (cycleTime >= circleFadeInStart && cycleTime < circleFadeInEnd) {
        float t = (cycleTime - circleFadeInStart) / (circleFadeInEnd - circleFadeInStart);
        circleAlpha = smoothstep(0.0, 1.0, t);
    } else if (cycleTime >= circleFadeInEnd && cycleTime < circleHoldEnd) {
        circleAlpha = 1.0;
    } else if (cycleTime >= circleHoldEnd && cycleTime < circleFadeOutEnd) {
        float t = (cycleTime - circleHoldEnd) / (circleFadeOutEnd - circleHoldEnd);
        circleAlpha = 1.0 - smoothstep(0.0, 1.0, t);
    }
    // otherwise circleAlpha remains 0

    //-----------------------------------------
    // 6) Convert the fragment coordinate tc
    //    to a [-1..1] range for easy shaping
    //-----------------------------------------
    // (tc in [0..1], so shift+scale to [-1..1])
    vec2 uv = tc * 2.0 - 1.0;
    // Account for aspect ratio if needed
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    //-----------------------------------------
    // 7) Draw fractal and circle
    //-----------------------------------------
    // Fractal
    vec4 fractalCol = drawJulia(uv, fractalCenter, fractalSeed);
    fractalCol.a *= fractalAlpha; // fade in/out

    // Circle
    vec4 circleCol = drawPulsingCircle(uv, circleCenter, circleRadius);
    circleCol.a *= circleAlpha;

    //-----------------------------------------
    // 8) Combine with the background texture
    //-----------------------------------------
    // Over-blend fractal
    color = mix(color, fractalCol, fractalCol.a);
    // Over-blend circle
    color = mix(color, circleCol, circleCol.a);
}
