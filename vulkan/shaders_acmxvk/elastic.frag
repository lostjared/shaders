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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    vec2 center = vec2(0.5, 0.5);
    
    // Compute vector from center
    vec2 tcFromCenter = tc - center;
    float distance = length(tcFromCenter);
    float angle = atan(tcFromCenter.y, tcFromCenter.x);
    
    // Spin effect
    float spinSpeed = time_f * 2.0; 
    angle += spinSpeed;
    
    // Elastic stretching and bending effect
    float elasticity = 0.3 + sin(time_f * 2.0) * 0.2;
    float stretch = 1.0 + sin(time_f * 3.0) * 0.3;
    float wave = sin(distance * 10.0 + time_f * 5.0) * elasticity;
    
    // Apply transformations
    float radius = distance * (stretch + wave);
    vec2 distortedTC = center + vec2(cos(angle), sin(angle)) * radius;

    // Clamp the coordinates to stay within bounds
    distortedTC = clamp(distortedTC, 0.0, 1.0);
    
    // Sample the texture
    color = texture(samp, distortedTC);
}
