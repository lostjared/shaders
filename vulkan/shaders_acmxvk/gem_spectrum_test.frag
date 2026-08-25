#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iTime ext.u0.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

// ACMX2 Standard Uniforms
layout(set = 0, binding = 0) uniform sampler2D samp;





// The New Hotness
layout(set = 0, binding = 3) uniform sampler1D spectrum; // Bound to unit 9

void main() {
    vec2 uv = tc;

    // 1. Sampling the Spectrum Data
    // We sample at specific points along the 1D texture (0.0 to 1.0)
    float bass   = texture(spectrum, 0.02).r; // Deep Kick/Sub (~86 Hz)
    float mid    = texture(spectrum, 0.15).r; // Vocals/Lead (~3.3 kHz)
    float treble = texture(spectrum, 0.5).r;  // Snares/Cymbals (~11 kHz)

    // 2. Frequency-Driven Geometry Warp
    // Bass creates a 'breathing' scale effect
    vec2 center = uv - 0.5;
    center *= 1.0 - (bass * 0.15);
    uv = center + 0.5;

    // Mid-range creates a lateral wavy 'shimmer'
    uv.x += sin(uv.y * 15.0 + iTime * 5.0) * (mid * 0.05);

    // 3. Chromatic Aberration (Tied to Treble)
    // High frequencies cause the RGB channels to split sharply
    float shift = treble * 0.1;
    float r = texture(samp, uv + vec2(shift, 0.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, uv - vec2(shift, 0.0)).b;
    vec3 result = vec3(r, g, b);

    // 4. Frequency Overlay (Testing Tool)
    // This draws a small 'oscilloscope' line at the bottom to verify signal
    if (uv.y < 0.05) {
        float freq_val = texture(spectrum, uv.x).r;
        if (uv.y < freq_val * 0.2) {
            result = mix(result, vec3(0.0, 1.0, 0.0), 0.8); // Green FFT bars
        }
    }

    // 5. Final Tone Mapping
    // Use bass to 'blow out' the brightness on heavy hits
    result *= 1.0 + (bass * 1.2);
    
    color = vec4(result, 1.0);
}