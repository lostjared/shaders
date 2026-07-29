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
const float THICKNESS = 1.0;     // Line width
const float THRESHOLD = 0.15;    // Noise gate (removes background)
const float NEON_SPEED = 3.0;    // Speed of color cycling

// --- Wobble Configuration ---
const float WOBBLE_AMP = 0.02;   // How strong the distortion is (try 0.01 to 0.05)
const float WOBBLE_FREQ = 10.0;  // How "tight" the waves are (try 5.0 to 20.0)
const float WOBBLE_SPEED = 2.0;  // How fast the wobble moves

// Helper: Converts RGB to Grayscale
float getGray(vec4 c) {
    return dot(c.rgb, vec3(0.299, 0.587, 0.114));
}

// Helper: Neon Palette Generator
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557); 
    return a + b * cos(6.28318 * (c * t + d));
}

void main(void) {
    // 1. Calculate the Wobble (Distortion)
    // We create an offset based on Sine/Cosine waves, Time, and Position.
    vec2 wobbleOffset;
    wobbleOffset.x = sin(tc.y * WOBBLE_FREQ + iTime * WOBBLE_SPEED) * WOBBLE_AMP;
    wobbleOffset.y = cos(tc.x * WOBBLE_FREQ + iTime * WOBBLE_SPEED) * WOBBLE_AMP;

    // Apply the offset to the original coordinates
    vec2 distortedTC = tc + wobbleOffset;

    // 2. Calculate texel size
    vec2 texel = vec2(THICKNESS) / iResolution.xy;

    // 3. Sobel Edge Detection (Using distortedTC instead of tc)
    // We sample relative to the distorted coordinates to make the edges "ride" the waves.
    float t00 = getGray(texture(samp, distortedTC + vec2(-1, -1) * texel));
    float t10 = getGray(texture(samp, distortedTC + vec2( 0, -1) * texel));
    float t20 = getGray(texture(samp, distortedTC + vec2( 1, -1) * texel));
    
    float t01 = getGray(texture(samp, distortedTC + vec2(-1,  0) * texel));
    float t21 = getGray(texture(samp, distortedTC + vec2( 1,  0) * texel));
    
    float t02 = getGray(texture(samp, distortedTC + vec2(-1,  1) * texel));
    float t12 = getGray(texture(samp, distortedTC + vec2( 0,  1) * texel));
    float t22 = getGray(texture(samp, distortedTC + vec2( 1,  1) * texel));

    float Gx = t00 + 2.0 * t10 + t20 - t02 - 2.0 * t12 - t22;
    float Gy = t00 + 2.0 * t01 + t02 - t20 - 2.0 * t21 - t22;

    float edge = sqrt(Gx * Gx + Gy * Gy);

    // 4. Discard Background / Noise
    if (edge < THRESHOLD) {
        color = vec4(0.0, 0.0, 0.0, 1.0); 
        return;
    }

    // 5. Color Output
    edge = smoothstep(THRESHOLD, THRESHOLD + 0.1, edge);
    
    // We use the distorted coordinates for the color pattern too, so the colors stick to the lines
    vec3 neonColor = palette(length(distortedTC) + iTime * NEON_SPEED * 0.1);

    color = vec4(neonColor * edge, 1.0);
}