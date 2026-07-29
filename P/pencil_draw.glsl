#version 330 core

in vec2 tc;
out vec4 color;

const float THICKNESS = 1.0;

// Minimum edge strength required to show color (filters out noise in black areas)
const float THRESHOLD = 0.1;

// How fast the neon colors cycle
const float SPEED = 2.0;

// --- Uniforms (Kept exactly as requested) ---
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
// How thick the edge check is (1.0 is standard pixel neighbor)
#define THICKNESS 1.0
// Minimum edge strength required to show color (filters out noise in black areas)
#define THRESHOLD 0.1 
// How fast the neon colors cycle
#define SPEED 2.0

// Helper: Converts RGB to Grayscale for edge calculation
float getGray(vec4 c) {
    return dot(c.rgb, vec3(0.299, 0.587, 0.114));
}

// Helper: Cosine based palette for Neon colors (Inigo Quilez method)
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

void main(void) {
    // 1. Calculate texel size based on resolution
    vec2 texel = vec2(THICKNESS) / iResolution.xy;

    // 2. Sobel Kernel (Edge Detection)
    // We sample the neighbors around the current pixel
    // Gx = Horizontal differences, Gy = Vertical differences
    float t00 = getGray(texture(samp, tc + vec2(-1, -1) * texel));
    float t10 = getGray(texture(samp, tc + vec2( 0, -1) * texel));
    float t20 = getGray(texture(samp, tc + vec2( 1, -1) * texel));
    
    float t01 = getGray(texture(samp, tc + vec2(-1,  0) * texel));
    float t21 = getGray(texture(samp, tc + vec2( 1,  0) * texel));
    
    float t02 = getGray(texture(samp, tc + vec2(-1,  1) * texel));
    float t12 = getGray(texture(samp, tc + vec2( 0,  1) * texel));
    float t22 = getGray(texture(samp, tc + vec2( 1,  1) * texel));

    // Apply Sobel matrix
    float Gx = t00 + 2.0 * t10 + t20 - t02 - 2.0 * t12 - t22;
    float Gy = t00 + 2.0 * t01 + t02 - t20 - 2.0 * t21 - t22;

    // 3. Calculate Edge Magnitude
    float edge = sqrt(Gx * Gx + Gy * Gy);

    // 4. Clean up the edges
    // If the edge is very weak (noise in the black pixels), clamp it to 0
    edge = smoothstep(THRESHOLD, THRESHOLD + 0.1, edge);

    // 5. Generate Neon Color
    // We use the pixel coordinates (tc.xy) and time to vary the color
    vec3 neon = palette(length(tc) + iTime * SPEED * 0.2);

    // 6. Output
    // If edge is 0 (black area), output black. If edge is 1, output neon.
    color = vec4(neon * edge, 1.0);
}