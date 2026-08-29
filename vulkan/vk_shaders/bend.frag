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
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;





float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    // Normalize texture coordinates to range [0.0, 1.0]
    vec2 uv = tc;
    
    // Calculate a time-based parameter
    float t = mod(time_f, 10.0) * 0.1;
    
    // Determine rotation angle influenced by time
    float angle = sin(t * 3.14159265) * 0.5;
    
    // Define the center of the effect
    vec2 center = vec2(0.5, 0.5);
    
    // Translate UV coordinates to center
    vec2 centeredUV = uv - center;
    
    // Calculate distance from center
    float dist = length(centeredUV);
    
    // Compute bending factor influenced by amplitude
    float bend = sin(dist * 6.0 - t * 2.0 * 3.14159265) * 0.05 * amp * uamp;
    
    // Create a rotation matrix
    mat2 rotation = mat2(cos(angle), -sin(angle),
                         sin(angle),  cos(angle));
    
    // Apply rotation to UV coordinates
    vec2 rotatedUV = rotation * centeredUV;
    
    // Translate UV coordinates back from center
    vec2 finalUV = rotatedUV + center;
    
    // Apply ping-pong time modulation
    float time_t = pingPong(time_f, 10.0);
    
    // Apply distortion influenced by amplitude
    // The distortion is scaled by both amp and uamp
    finalUV += sin(bend * rotatedUV * time_t) * amp * uamp;
    
    // Optionally, incorporate resolution for more intricate effects
    // Example: finalUV += (sin(bend * rotatedUV * time_t) * amp * uamp) / iResolution;
    
    // Sample the texture with the distorted UV coordinates
    color = texture(samp, finalUV);
    color = vec4(sin(color.rgb * (time_t+2.0)), 1.0);
}
