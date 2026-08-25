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
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;





void main(void) {
    // Convert mouse positions to texture space (0-1)
    vec2 mouseUV = iMouse.xy / iResolution.xy;
    vec2 clickUV = iMouse.zw / iResolution.xy;
    vec2 drag = mouseUV - clickUV;
    
    // Calculate distance from current pixel to click position
    float dist = distance(tc, clickUV);
    
    // Calculate falloff using smoothstep for better control
    float radius = uamp;
    float falloff = 1.0 - smoothstep(0.0, radius, dist);
    
    // Apply displacement with amplitude control
    vec2 displacedTC = tc + drag * falloff * time_f;
    
    // Sample texture with displaced coordinates
    color = texture(samp, displacedTC);
}