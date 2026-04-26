#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

// Basic NTSC-inspired faded color palette constants
const vec3 VHS_BLACK = vec3(0.01, 0.0, 0.03); 
const vec3 VHS_RED = vec3(0.65, 0.1, 0.2);   
const vec3 VHS_GREEN = vec3(0.0, 0.55, 0.4); 

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    // 1. Audio Analysis
    float bass   = texture(spectrum, 0.05).r;
    float mid    = texture(spectrum, 0.30).r;
    float treble = texture(spectrum, 0.70).r;

    vec2 uv = tc;

    // 2. Horizontal Tracking & Jitter
    // Small high-frequency wiggle
    float jitter = (hash(vec2(time_f, uv.y)) - 0.5) * 0.003 * (0.5 + treble);
    
    // Large horizontal "tear" based on bass intensity
    float drift = sin(uv.y * 10.0 + time_f) * 0.002;
    float jump = step(0.98, hash(vec2(time_f * 0.5, 0.0))) * sin(uv.y * 100.0) * 0.02 * bass;
    
    uv.x += jitter + drift + jump;

    // 3. Chromatic Aberration (RGB Color Fringe)
    // Red and Blue channels are shifted horizontally to simulate tape alignment issues
    float fringe = 0.005 + (mid * 0.02);
    vec3 col;
    col.r = texture(samp, uv + vec2(fringe, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(fringe, 0.0)).b;

    // 4. Phosphor Ghosting / Trail
    // Mixing in a slightly shifted version of the green channel for a "smear" effect
    float ghost = texture(samp, uv - vec2(0.01, 0.005)).g;
    col.g = mix(col.g, ghost, 0.3 * mid);

    // 5. VHS Artifacts
    // Scanlines (Moving slightly with the vertical sync)
    float scanline = sin(uv.y * iResolution.y * 0.7 + time_f * 5.0) * 0.08;
    col -= scanline;

    // Fine grain/static noise
    float staticNoise = hash(uv + time_f) * 0.12 * (1.0 + amp_smooth);
    col += staticNoise;

    // Tape dropouts (Horizontal white streaks)
    float dropout = step(0.996, hash(vec2(time_f, uv.y * 15.0))) * (0.5 + bass);
    col += dropout * 0.6;

    // 6. Signal Color Grading
    // Desaturate and shift blacks toward blue (faded magnetic look)
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(gray), 0.2); 
    col = max(col, VHS_BLACK); // Lift the blacks

    // 7. Feedback Flash (Glitch)
    // Invert the colors on high peaks to simulate signal overload
    if (amp_peak > 0.97) {
        col = 1.0 - col;
    }

    // Vignette (Simulates the curvature of a CRT screen)
    float vig = smoothstep(0.7, 0.2, length(tc - 0.5));
    col *= (vig + 0.3);

    // Final Gain control
    col *= 0.8 + amp_smooth * 0.5;

    color = vec4(col, 1.0);
}