#version 330 core
// Infinite Log-Polar Fractal Tunnel

in vec2 tc;
out vec4 color;

// --- Base Inputs ---
uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 neonRing(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    // ==========================================
    // 1. AUDIO SAMPLING
    // ==========================================
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= (iResolution.x / iResolution.y);

    // ==========================================
    // 2. LOG-POLAR TUNNEL MAPPING
    // ==========================================
    float radius = max(length(uv), 0.0001); 
    float angle = atan(uv.y, uv.x);

    // Tweak these to change the physical structure of the tunnel
    float tunnelSpeed = 0.4;
    float tunnelDensity = 2.0;

    // log(radius) creates the depth. Subtracting iTime moves us infinitely forward.
    vec2 polarUV = vec2(log(radius) - iTime * tunnelSpeed, angle / 3.14159);

    // Tile the coordinate space
    vec2 p = fract(polarUV * tunnelDensity) * 2.0 - 1.0;
    
    // Audio pulse directly on the geometry
    p *= 1.0 + bass * 0.4;

    // ==========================================
    // 3. FRACTAL GENERATION (Carving the walls)
    // ==========================================
    float iters = 0.0;
    const float maxIters = 50.0;
    vec2 c = vec2(0.8 + mid * 0.2, 0.5 + 0.1 * sin(iTime * 0.25));
    
    for (float i = 0.0; i < maxIters; i++) {
        p = abs(p) / dot(p, p) - c;
        if (length(p) > 20.0) break;
        iters++;
    }
    float norm = iters / maxIters;

    // ==========================================
    // 4. TEXTURING & CHROMATIC ABERRATION
    // ==========================================
    // Wrap the base video/texture along the tunnel walls, distorted by the fractal
    vec2 sampUV = fract(polarUV * 1.0 + p * 0.02);

    float chroma = (mid + treble) * 0.035;
    vec3 baseCol;
    baseCol.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseCol.g = texture(samp, sampUV).g;
    baseCol.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // ==========================================
    // 5. LIGHTING & NEON BLOOMS
    // ==========================================
    vec3 bloomAccum = vec3(0.0);
    for (float i = 0.0; i < 5.0; i++) {
        float ringDist = abs(norm - (i + 1.0) * 0.15);
        float ring = pow(0.01 / max(ringDist, 0.001), 0.8);
        float freq = texture(spectrum, (i + 1.0) * 0.08).r;
        bloomAccum += neonRing(i * 0.2 + iTime * 0.15 + freq) * ring * 0.12;
    }
    baseCol += bloomAccum;

    // Apply fractal iteration coloring
    vec3 fracCol;
    fracCol.r = norm * 1.5;
    fracCol.g = sin(iters * 0.4 + iTime);
    fracCol.b = length(p) * 0.08;
    baseCol = mix(baseCol, baseCol * (fracCol + 0.5), 0.25 + hiMid * 0.2);

    // Deep tunnel fade (fades to black at the absolute center of the screen)
    float distanceFade = smoothstep(0.0, 1.2, radius * 4.0);
    baseCol *= distanceFade;

    // Global audio flash/inversion
    baseCol *= 0.85 + amp_smooth * 0.35;
    baseCol *= 1.0 + bass * 0.3;
    baseCol = mix(baseCol, vec3(1.0) - baseCol, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(clamp(baseCol, 0.0, 1.0), 1.0);
}