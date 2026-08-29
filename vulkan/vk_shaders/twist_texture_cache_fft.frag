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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
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

// Audio and core uniforms








layout(set = 0, binding = 3) uniform sampler1D spectrum0;

// Helper to fetch history frames
vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp, uv);  
    if (idx == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0)))); 
    if (idx == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (idx == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (idx == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (idx == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (idx == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (idx == 7) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

void main(void) {
    vec2 center = vec2(0.5, 0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution.xy;
    }

    // FFT driven ripple dynamics
    float rippleSpeed = 5.0 + amp_high * 10.0;
    float rippleAmplitude = 0.03 + (amp_mid * 0.05);
    float rippleWavelength = 10.0 - (amp_low * 2.0);
    
    // Base twist strength from vertical mouse position
    float baseTwist = 1.0;
    if (iMouse.z > 0.0 || iMouse.w > 0.0) {
        baseTwist = (iMouse.y / iResolution.y) * 4.0;
    }
    
    // Modulate overall twist strength with the smooth audio envelope
    float audioTwist = baseTwist * (1.0 + amp_smooth * 2.5);

    float radius = length(tc - center);
    
    // Base ripple displacement
    float ripple = sin(tc.x * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    ripple += sin(tc.y * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    vec2 rippleTC = tc + vec2(ripple, ripple);
    
    vec4 accum = vec4(0.0);
    float weightSum = 0.0;
    
    // Audio stretching: Heavy bass pulls the stretch factor below 1.0, 
    // causing a zooming out/stretching effect on the echo layers
    float audioStretch = 1.0 - (amp_low * 0.3);

    for(int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // Fetch live FFT at a specific frequency bin based on the cache layer
        float layerFFT = texture(spectrum0, gen * 0.1).r;
        
        // Phase-shift the twist angle using the generation index and mid-frequencies
        float echoTwist = audioTwist * (radius - 1.0) + time_f - (gen * (0.2 + amp_mid * 0.1));
        
        float cosA = cos(echoTwist);
        float sinA = sin(echoTwist);
        mat2 rotationMatrix = mat2(cosA, -sinA, sinA, cosA);
        
        // Apply recursive stretch per generation driven by bass
        vec2 stretchedTC = rippleTC - center;
        stretchedTC *= pow(audioStretch, gen + 1.0); 
        
        // Apply rotation around the dynamic center
        vec2 twistedTC = (rotationMatrix * stretchedTC) + center;
        
        vec4 cached = sampleCache(i, twistedTC);
        
        // Dynamic Fade: The weight drops off slower when audio peaks hit,
        // pushing the visible echo deeper into the historical cache
        float weight = pow(0.75 + (amp_peak * 0.15), gen);
        
        // Add a slight audio-reactive chromatic shift to the older echoes
        if (gen > 0.0) {
            cached.r *= 1.0 + (layerFFT * 0.5);
            cached.b *= 1.0 + (amp_high * 0.5);
        }
        
        accum += cached * weight;
        weightSum += weight;
    }

    // Normalize the accumulated colors
    color = clamp(accum / weightSum, 0.0, 1.0);
}