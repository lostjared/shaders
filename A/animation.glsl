#version 330 core

in vec2 tc;
out vec4 color;

// --- Uniforms ---
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame;
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;

// --- Configuration ---
const float FLOW_SPEED = 0.5;  // How fast the liquid moves
const float SWIRL_SCALE = 3.0; // Size of the swirls (lower = bigger swirls)
const float DISTORTION = 0.2;  // Intensity of the melt effect
const float RGB_SPLIT = 0.02;  // How much the colors separate (0.0 = none)

// --- Noise Functions ---
// Simple hash function to generate randomness
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 2D Noise based on value interpolation
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Smooth interpolation (cubic hermite)
    f = f * f * (3.0 - 2.0 * f);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

// Fractal Brownian Motion (FBM)
// Adds layers of noise together to create complex, cloud-like patterns
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;

    // Loop to add layers (octaves)
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(st);
        st *= 2.0;        // Double the frequency
        amplitude *= 0.5; // Halve the amplitude
    }
    return value;
}

void main(void) {
    vec2 uv = tc;

    // 1. Create the Swirl Pattern (Domain Warping)
    // We use FBM to distort the coordinates.
    // 'q' is a noise pattern moving with time.
    vec2 q = vec2(0.0);
    q.x = fbm(uv * SWIRL_SCALE + iTime * FLOW_SPEED * 0.1);
    q.y = fbm(uv * SWIRL_SCALE + vec2(1.0));

    // 'r' is a second layer of noise that uses 'q' to distort itself.
    // This creates the "folding" liquid look.
    vec2 r = vec2(0.0);
    r.x = fbm(uv * SWIRL_SCALE + 1.0 * q + vec2(1.7, 9.2) + 0.15 * iTime * FLOW_SPEED);
    r.y = fbm(uv * SWIRL_SCALE + 1.0 * q + vec2(8.3, 2.8) + 0.126 * iTime * FLOW_SPEED);

    // 2. Calculate the final distorted coordinates
    // We mix the original UVs with the noise 'r'
    vec2 distortedUV = uv + r * DISTORTION;

    // 3. Chromatic Aberration (RGB Split)
    // Instead of sampling the texture once, we sample it 3 times at slightly different positions.
    // This adds that "cool" glitch/holographic fringe to the edges.

    float rChannel = texture(samp, distortedUV + vec2(RGB_SPLIT, 0.0)).r;
    float gChannel = texture(samp, distortedUV).g; // Green stays center
    float bChannel = texture(samp, distortedUV - vec2(RGB_SPLIT, 0.0)).b;

    // 4. Combine channels
    vec3 finalColor = vec3(rChannel, gChannel, bChannel);

    // 5. Optional: Add a subtle overlay of the flow pattern itself
    // This makes the "invisible" flows slightly visible, adding texture to black areas
    float flowPattern = length(q);
    finalColor += vec3(0.1, 0.05, 0.2) * flowPattern * 0.5;
    color = vec4(finalColor, 1.0);
}