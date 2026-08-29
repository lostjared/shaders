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



void main(void) {
    vec2 normPos = (gl_FragCoord.xy / iResolution.xy) * 2.0 - 1.0;
    float dist = length(normPos);
    
    // Mouse interaction parameters
    vec2 dragVec = vec2(0.0);
    float dragSpeed = 0.0;
    vec2 dragDir = vec2(0.0);
    float verticalFactor = 0.0;
    
    if(iMouse.z > 0.0) { // Only when mouse is dragged
        vec2 clickPos = (iMouse.zw / iResolution.xy) * 2.0 - 1.0;
        vec2 currentPos = (iMouse.xy / iResolution.xy) * 2.0 - 1.0;
        dragVec = currentPos - clickPos;
        dragSpeed = length(dragVec);
        dragDir = normalize(dragVec);
        verticalFactor = dragVec.y;
    }

    // Dynamic wave parameters based on drag
    float speedFactor = 1.0 + verticalFactor * 2.0;
    float waveSize = 0.105 + dragSpeed * 0.2;
    float phase = sin(dist * 6.0 - time_f * speedFactor);
    
    // Directional distortion effect
    vec2 displacement = mix(
        normPos * waveSize * phase, // Base effect
        dragDir * waveSize * phase * (1.0 + dragSpeed * 2.0), // Dragged effect
        smoothstep(0.0, 0.5, dragSpeed) // Blend between effects
    );
    
    vec2 tcAdjusted = tc + displacement;
    color = texture(samp, tcAdjusted);
}