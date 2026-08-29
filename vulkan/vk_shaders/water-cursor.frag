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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



float u_radius = 0.3; // Easy-to-edit radius variable

void main(void) {
    // Convert mouse position to texture coordinates [0-1] range
    vec2 mouseUV = iMouse.xy / iResolution.xy;
    
    // Calculate distance from current pixel to mouse
    float dist = distance(tc, mouseUV);
    
    // Create smooth falloff effect within radius
    float influence = 1.0 - smoothstep(u_radius * 0.8, u_radius, dist);
    
    // Water effect parameters
    float speed = 5.0;
    float amplitude = 0.03 * influence; // Scale effect by influence
    float wavelength = 10.0;
    
    // Wave calculations
    float rippleX = sin(tc.x * wavelength + time_f * speed) * amplitude;
    float rippleY = sin(tc.y * wavelength + time_f * speed) * amplitude;
    
    // Apply distortion only within influenced area
    vec2 rippleTC = mix(tc, tc + vec2(rippleX, rippleY), influence);
    
    // Sample textures
    vec4 originalColor = texture(samp, tc);
    vec4 rippleColor = texture(samp, rippleTC);
    
    // Blend between original and distorted texture
    color = mix(originalColor, rippleColor, influence);
}