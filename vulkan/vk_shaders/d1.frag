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
    vec2 uv = tc;
    
    // Create distortion parameters
    float waveSpeed = 1.1;
    float waveIntensity = 0.26;
    float waveDensity =  8.0;
    
    // Generate horizontal and vertical distortions
    float horizontalDistortion = sin(uv.y * waveDensity + time_f * waveSpeed) * waveIntensity;
    float verticalDistortion = sin(uv.x * (waveDensity * 0.8) + time_f * waveSpeed * 1.2) * waveIntensity;
    
    // Apply distortion to texture coordinates
    uv.x += horizontalDistortion;
    uv.y += verticalDistortion;
    
    // Add radial distortion for more complex effect
    vec2 center = vec2(0.5);
    float distanceFromCenter = length(uv - center);
    float radialDistortion = sin(distanceFromCenter * 15.0 - time_f * 3.0) * 0.015;
    uv += (uv - center) * radialDistortion;

    color = texture(samp, uv);
}