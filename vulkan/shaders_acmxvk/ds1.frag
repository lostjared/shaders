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


void main(void) {
    // Center coordinates and scale
    vec2 uv = tc * 2.0 - 1.0;
    
    // Polar coordinates conversion
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);
    
    // Kaleidoscope parameters
    const int slices = 6;  // Number of mirror slices
    float angleSlice = 2.0 * 3.14159 / float(slices);
    
    // Create rotational symmetry and mirroring
    angle = mod(angle, angleSlice * 2.0);
    angle = abs(angle - angleSlice);
    
    // Add time-based rotation
    angle += time_f * 0.5;
    
    // Dynamic distortion effects
    radius *= 1.0 + 0.1 * sin(time_f * 2.0 + angle * 5.0);
    angle += sin(time_f * 1.5 + radius * 5.0) * 0.3;
    
    // Convert back to Cartesian coordinates
    vec2 distortedUV = vec2(cos(angle), sin(angle)) * radius;
    
    // Create swirling effect
    distortedUV *= 0.5 + 0.3 * sin(time_f + radius * 3.0);
    
    // Mirror and tile pattern
    distortedUV = abs(fract(distortedUV * 1.5) * 2.0 - 1.0);
    
    // Final texture sampling with perspective warp
    vec2 finalUV = (distortedUV + 1.0) * 0.5;
    finalUV = fract(finalUV + vec2(time_f * 0.1, 0.0));
    
    color = texture(samp, finalUV);
    
    // Add color cycling effect (optional)
    color.rgb = mix(color.rgb, fract(color.rgb + time_f * 0.1), 0.2);
}