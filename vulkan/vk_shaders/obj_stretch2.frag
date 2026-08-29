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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    // Convert coordinates to [0,1] range
    vec2 currentPos = iMouse.xy / iResolution;
    // Current mouse position
    vec2 clickPos = iMouse.zw / iResolution;    
    // Initial click position

    if (iMouse.z > 0.0) { // Only when dragging
        vec2 drag = currentPos - clickPos;
        float dist = distance(tc, clickPos);
        
        float radius = 0.3;
        float strength = 0.5;
        float falloff = 1.0 - smoothstep(0.0, radius, dist);
        
        // Reverse direction by SUBTRACTING the displacement
        vec2 deformedUV = tc - (drag * falloff * strength);
        color = texture(samp, deformedUV);
    } else {
        color = texture(samp, tc);
    }
}