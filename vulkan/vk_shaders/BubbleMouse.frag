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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




void main(void) {
    vec2 uv = tc * 2.0 - 1.0; // Convert to [-1, 1] range
    vec2 distort = uv; // Default to no distortion
    float bubble = 0.0;

    // Check if the mouse is being dragged (zw is initial click position)
    if (iMouse.z != 0.0 || iMouse.w != 0.0) {
        // Convert mouse positions to UV space [-1, 1]
        vec2 clickPos = (iMouse.zw / iResolution.xy) * 2.0 - 1.0;
        vec2 currentPos = (iMouse.xy / iResolution.xy) * 2.0 - 1.0;
        vec2 dragVec = currentPos - clickPos;
        float dragLen = length(dragVec);
        vec2 dragDir = normalize(dragVec + vec2(0.0001)); // Avoid division by zero
        
        // Center UV around click position
        vec2 uv_centered = uv - clickPos;
        
        // Stretch UV along the drag direction
        float parallel = dot(uv_centered, dragDir);
        vec2 perp = uv_centered - parallel * dragDir;
        parallel *= 1.0 + dragLen * 3.0; // Adjust stretch intensity
        vec2 stretchedUV = perp + parallel * dragDir;
        float lenStretched = length(stretchedUV);
        
        // Calculate bubble intensity
        bubble = smoothstep(0.6, 0.9, 1.0 - lenStretched);
        
        // Apply distortion effect
        distort = clickPos + stretchedUV * (1.0 + 0.1 * sin(time_f + lenStretched * 20.0));
    }
    
    // Convert distorted coordinates back to texture space [0, 1]
    vec2 texCoord = distort * 0.5 + 0.5;
    vec4 texColor = texture(samp, texCoord);
    
    // Mix with white based on bubble intensity
    color = mix(texColor, vec4(1.0), bubble);
}