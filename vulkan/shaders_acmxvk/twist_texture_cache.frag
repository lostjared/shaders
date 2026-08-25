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
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

// Live feed and 8-frame cache layers
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif




// Helper to fetch history frames
vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp, uv);  // Live feed
    if (idx == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0)))); // History frames start here
    if (idx == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (idx == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (idx == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (idx == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (idx == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (idx == 7) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

void main(void) {
    // Determine the center point based on left mouse click
    vec2 center = vec2(0.5, 0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution.xy;
    }

    float rippleSpeed = 5.0;
    float rippleAmplitude = 0.03;
    float rippleWavelength = 10.0;
    
    // Dynamic twist strength based on vertical mouse position
    float twistStrength = 1.0;
    if (iMouse.z > 0.0 || iMouse.w > 0.0) {
        twistStrength = (iMouse.y / iResolution.y) * 4.0;
    }

    float radius = length(tc - center);
    
    // Base ripple displacement
    float ripple = sin(tc.x * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    ripple += sin(tc.y * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    vec2 rippleTC = tc + vec2(ripple, ripple);
    
    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    // Loop through the live frame (0) and the 8 cached frames
    for(int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // The Echo Twist logic
        // We offset the angle based on the historical generation (gen)
        // Older frames get a delayed angle, creating the temporal twist trail
        float echoTwist = twistStrength * (radius - 1.0) + time_f - (gen * 0.2);
        
        float cosA = cos(echoTwist);
        float sinA = sin(echoTwist);
        mat2 rotationMatrix = mat2(cosA, -sinA, sinA, cosA);
        
        // Apply rotation around the dynamic center
        vec2 twistedTC = (rotationMatrix * (rippleTC - center)) + center;
        
        // Sample the correct layer of the temporal cache
        vec4 cached = sampleCache(i, twistedTC);
        
        // Older frames have less weight, causing the echo to fade out smoothly
        float weight = pow(0.75, gen);
        
        accum += cached * weight;
        weightSum += weight;
    }

    // Normalize the accumulated colors
    color = accum / weightSum;
}