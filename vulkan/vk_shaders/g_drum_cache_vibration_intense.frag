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
    vec2 center = (iMouse.z > 0.0) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    vec2 d = tc - center;
    float r = length(d);
    vec2 dir = d / max(r, 1e-6);

    // Audio mechanics for the strike force (Baseline increased slightly for heavier kicks)
    float strikeForce = (amp_low * 3.0) + (amp_peak * 1.5);
    
    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    for (int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // 1. Outward Propagation
        float waveRadius = (gen * 0.06) + (amp_low * 0.05); 
        float distToWave = abs(r - waveRadius);
        
        // 2. The Shockwave Pulse
        float pulseSharpness = 40.0 - (amp_mid * 15.0);
        float pulse = exp(-distToWave * pulseSharpness);
        
        float bandFFT = texture(spectrum0, clamp(waveRadius, 0.0, 1.0)).r;
        
        // 3. Membrane Jitter
        float skinJitter = sin(r * 150.0 - time_f * 25.0) * bandFFT * amp_high;
        
        // 3X INTENSITY MULTIPLIERS APPLIED HERE
        // The physical structural pulse and the high-end jitter are significantly amplified
        float displacement = (pulse * strikeForce * 0.45) + (skinJitter * 0.09);
        
        float amplitude = displacement * pow(0.65, gen);
        
        vec2 uv = tc + dir * amplitude;
        vec4 cached = sampleCache(i, uv);
        
        // 4. Chromatic Impact Tearing
        if (pulse > 0.1 && gen > 0.0) {
            // Chromatic separation boosted 3x to match the extreme physical displacement
            float chromaOffset = pulse * strikeForce * 0.06 * pow(0.8, gen);
            cached.r = sampleCache(i, uv + dir * chromaOffset).r;
            cached.b = sampleCache(i, uv - dir * chromaOffset).b;
            
            // Additive energy flash on the wave crest doubled for visibility
            cached.rgb += vec3(0.2, 0.4, 0.5) * pulse * bandFFT * strikeForce * pow(0.7, gen) * 2.0;
        }
        
        float weight = pow(0.82 + (amp_smooth * 0.1), gen);
        accum += cached * weight;
        weightSum += weight;
    }

    color = vec4(clamp(accum / weightSum, 0.0, 1.0).rgb, 1.0);
}