#version 330 core
// ant_gem_fractal_ocean_repeat
// Seamless deep-zoom repeat variant of ant_gem_fractal_ocean.
// Runs through a full zoom cycle, then blends the deepest state back
// into the start so the motion repeats without a hard reset seam.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 ocean(float t) {
    vec3 a = vec3(0.1, 0.3, 0.5);
    vec3 b = vec3(0.3, 0.4, 0.5);
    vec3 c = vec3(1.0, 1.2, 1.0);
    vec3 d = vec3(0.0, 0.25, 0.5);
    return a + b * cos(6.28318 * (c * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec2 repeatUV(vec2 uv) {
    return fract(uv + vec2(0.173, 0.231));
}

// Run the escape-time fractal for a given starting point; returns
// normalized iteration count and the final warped position used for
// texture distortion.
void fractalIter(vec2 p, float mid, float iTimeLocal, out float normIters, out vec2 pOut) {
    float iters = 0.0;
    const float max_iters = 48.0;
    for (float i = 0.0; i < max_iters; i++) {
        p = abs(p) / dot(p, p) - vec2(0.8 + mid * 0.3, 0.5 + 0.1 * sin(iTimeLocal * 0.3));
        if (length(p) > 20.0) break;
        iters++;
    }
    normIters = iters / max_iters;
    pOut = p;
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.20).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Preserve the original deep zoom range, but blend the tail of the
    // cycle back into the start so it repeats instead of snapping.
    float zoomPhase = iTime * 0.3;
    const float cycleDepth = 8.0;
    const float blendSpan = 1.25;
    float cyclePos = mod(zoomPhase, cycleDepth);
    float zoomA = pow(0.5, cyclePos) * (1.0 + bass * 0.5);
    float zoomB = pow(0.5, cyclePos - cycleDepth) * (1.0 + bass * 0.5);

    // Only blend near the end of the cycle so most of the run keeps the
    // full-depth zoom motion before easing into the next pass.
    float w = smoothstep(cycleDepth - blendSpan, cycleDepth, cyclePos);

    float nA, nB;
    vec2 pA, pB;
    fractalIter(uv * zoomA, mid, iTime, nA, pA);
    fractalIter(uv * zoomB, mid, iTime, nB, pB);

    float normIters = mix(nA, nB, w);
    vec2 p = mix(pA, pB, w);

    // Liquid ripple distortion on texture coords
    vec2 texUV = tc + p * 0.015;
    float ripple = noise(tc * 6.0 + iTime * 0.5) * 0.04 * (1.0 + mid);
    texUV += vec2(sin(texUV.y * 15.0 + iTime * 3.0), cos(texUV.x * 15.0 + iTime * 3.0)) * ripple;

    // Use straight repeat wrapping instead of mirror folding. The old
    // mirror map created a hard derivative flip through the center of
    // the screen, which showed up as a visible seam.
    texUV = repeatUV(texUV);

    // Sample with chromatic split on treble
    float chroma = treble * 0.035;
    vec3 col;
    col.r = texture(samp, repeatUV(texUV + vec2(chroma, 0.0))).r;
    col.g = texture(samp, texUV).g;
    col.b = texture(samp, repeatUV(texUV - vec2(chroma, 0.0))).b;

    // Keep the palette in the same repeat domain as the zoom so the
    // color motion also loops without a visible jump.
    float palettePhase = mix(cyclePos, cyclePos - cycleDepth, w);
    vec3 oceanCol = ocean(normIters * 2.0 + palettePhase * 0.5 + bass);
    col = mix(col, col * oceanCol, 0.4 + hiMid * 0.3);

    // Deep glow rings
    float ringGlow = pow(0.01 / max(abs(sin(normIters * 8.0 + iTime)), 0.001), 0.8);
    col += oceanCol * ringGlow * 0.15 * (1.0 + air);

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.4;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
