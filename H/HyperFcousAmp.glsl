#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

// --- AUDIO UNIFORMS ---
// Ensure your host program passes these, or the simulation below will take over
uniform float amp;  // Bass / Volume (0.0 to 1.0)
uniform float uamp; // Treble / High Freq (0.0 to 1.0)

// --- UTILITIES ---
const float PI = 3.14159265359;

mat3 rotX(float a) {
    float s = sin(a), c = cos(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}
mat3 rotY(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}
mat3 rotZ(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, -s, 0, s, c, 0, 0, 0, 1);
}

// --- NOISE ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// --- PALETTE ---
vec3 electricPalette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}

// --- MAIN RENDER FUNCTION ---
vec3 renderLayer(vec2 uv, float t, float bassStr, float trebleStr) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 center = vec2(0.5);

    // Mouse Interaction: If mouse is pressed, move the vortex center
    if (iMouse.z > 0.5) {
        center = iMouse.xy / iResolution;
    }

    vec2 p = (uv - center) * ar;

    // 1. AUDIO-REACTIVE TWIST
    // The vortex tightens and spins faster when the BASS hits
    float len = length(p);
    float twistBase = 3.0 + (bassStr * 4.0); // Expands on beat
    float angle = atan(p.y, p.x) + twistBase / (len + 0.1) + t * (0.5 + bassStr);
    vec2 twistedP = vec2(cos(angle), sin(angle)) * len;

    // 2. AUDIO-REACTIVE RIPPLE
    // The glitch jitter increases when the TREBLE hits
    float rippleWavelength = 8.0;
    float rippleSpeed = 4.0 + (trebleStr * 10.0); // Fast jitter on highs
    float noiseVal = fbm(twistedP * 5.0 + t);

    float rippleX = sin(twistedP.x * rippleWavelength + t * rippleSpeed + noiseVal * 2.0);
    float rippleY = cos(twistedP.y * rippleWavelength + t * rippleSpeed - noiseVal * 2.0);

    // Treble makes the ripples sharper/deeper
    float rippleAmp = 0.05 + 0.05 * noiseVal * (1.0 + trebleStr * 2.0);
    vec2 rippledP = twistedP + vec2(rippleX, rippleY) * rippleAmp;

    // 3. 3D PROJECTION
    vec3 p3 = vec3(rippledP, 1.0);
    // BASS shakes the camera slightly
    float shake = bassStr * 0.1 * sin(t * 20.0);
    mat3 R = rotX(t * 0.2 + shake) * rotY(t * 0.15) * rotZ(t * 0.1);
    vec3 r = R * p3;
    float zScale = 1.0 / (1.0 + r.z * 0.5);
    vec2 projUV = r.xy * zScale;

    // 4. MIRROR TILING
    vec2 tiledUV = 1.0 - abs(1.0 - 2.0 * (projUV + 0.5));
    tiledUV = tiledUV - floor(tiledUV);

    // 5. CHROMATIC ABERRATION (Reacts to Bass)
    // Heavy bass = huge color split
    float aberrationStr = 0.01 + (0.04 + bassStr * 0.05) * (1.0 / (len + 0.5));
    vec2 offset = vec2(aberrationStr, 0.0);

    vec3 texR = texture(samp, clamp(tiledUV - offset, 0.0, 1.0)).rgb;
    vec3 texG = texture(samp, clamp(tiledUV, 0.0, 1.0)).rgb;
    vec3 texB = texture(samp, clamp(tiledUV + offset, 0.0, 1.0)).rgb;
    vec3 layerColor = vec3(texR.r, texG.g, texB.b);

    // 6. GLOW
    float glowMask = smoothstep(0.6, 0.95, abs(rippleX * rippleY));
    vec3 palette = electricPalette(len - t);

    // Flash brighter on beat
    return mix(layerColor, layerColor + palette, glowMask * (0.8 + bassStr * 0.5));
}

void main(void) {
    // --- SIMULATE AUDIO (If uniforms are 0.0) ---
    // If your app isn't sending audio data yet, this creates a fake "beat"
    // using sine waves so the shader doesn't look static.
    float simBass = (amp <= 0.001) ? abs(sin(time_f * 4.0)) * 0.5 : amp;
    float simTreble = (uamp <= 0.001) ? abs(cos(time_f * 8.0)) * 0.5 : uamp;

    // PASS 1: Current Frame
    vec3 col0 = renderLayer(tc, time_f, simBass, simTreble);

    // PASS 2: Echo 1
    vec3 col1 = renderLayer(tc, time_f - 0.1, simBass * 0.8, simTreble * 0.8);

    // PASS 3: Echo 2
    vec3 col2 = renderLayer(tc, time_f - 0.2, simBass * 0.6, simTreble * 0.6);

    vec3 finalColor = col0 + (col1 * 0.5) + (col2 * 0.25);
    finalColor = finalColor / (1.0 + finalColor * 0.4);

    color = vec4(finalColor, 1.0);
}