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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;


// Precise spectral palette to match the pinks and cyans in your image
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.3, 0.2, 0.2);
    return a + b * cos(6.28318 * (c * t + d));
}

void main(void) {
    // 1. Center coordinates
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    // 2. Geometry: Distance and Angle
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // 3. The "Zig-Zag" Ripple (The high complexity part)
    // We add a sine wave to the radius based on the angle to get those jagged edges
    float ripples = sin(angle * 12.0 + time_f) * 0.05;
    float dist = r + ripples;

    // 4. Create the Ring Pattern
    // This creates the repeating concentric circles seen in your image
    float ringPattern = sin(dist * 25.0 - time_f * 3.0);
    
    // 5. Controlled Texture Distortion
    // We only nudge the UVs slightly along the ring lines
    vec2 distortedUV = tc + (uv / r) * ringPattern * 0.02;
    vec4 tex = texture(samp, distortedUV);

    // 6. Color Synthesis
    // Map the rings to the spectrum
    vec3 ringColor = palette(dist * 2.0 - time_f * 0.5);
    
    // Add the "Hot Center" glow from your image
    float centerGlow = exp(-r * 4.0) * 1.2;
    
    // 7. Final Mix
    // We blend the texture with the rings, keeping the texture recognizable
    vec3 finalRGB = mix(tex.rgb, ringColor, 0.4);
    finalRGB += centerGlow * vec3(1.0, 0.95, 0.8); // Warm white core
    
    // Sharpen the bands slightly for that "digital" look
    finalRGB *= (0.8 + 0.2 * ringPattern);

    color = vec4(finalRGB, 1.0);
}