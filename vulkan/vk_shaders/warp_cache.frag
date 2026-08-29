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
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
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

// Historical FFT data (0 is now, 7 is oldest)
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

// System uniforms




// Audio uniforms






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

// Helper to fetch historical FFT data
float sampleSpectrumHistory(int idx, float freq) {
    if (idx <= 0) return texture(spectrum0, freq).r;
    if (idx == 1) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (idx == 2) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (idx == 3) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (idx == 4) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (idx == 5) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (idx == 6) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

void main(void) {
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution.xy;
    }

    vec2 uv_centered = tc - center;
    float radius = length(uv_centered);
    float angle = atan(uv_centered.y, uv_centered.x);

    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    // Base expansion force driven by live low frequencies
    float baseExpansion = 1.0 - (amp_low * 0.15);
    
    for (int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // Map the texture history index directly to the FFT history array
        int historyIdx = min(i, 7); 
        
        // Fetch historical low and high frequencies for this specific frame
        float histLow = sampleSpectrumHistory(historyIdx, 0.05);
        float histHigh = sampleSpectrumHistory(historyIdx, 0.75);

        // 1. EXPANSION
        // Scale UVs outward over time. Older frames stretch further out.
        float expansionFactor = pow(baseExpansion - (histLow * 0.05), gen);
        vec2 scaledUV = uv_centered * expansionFactor;

        // 2. WARP
        // Twist based on historical high frequencies. The warp gets more chaotic on older frames.
        float warpIntensity = histHigh * 0.5 + (amp_peak * 0.2);
        float warpAngle = angle + (sin(radius * 10.0 - time_f * 2.0) * warpIntensity * gen * 0.1);
        
        // Reconstruct UV coordinates after polar expansion and warping
        vec2 finalUV = vec2(cos(warpAngle), sin(warpAngle)) * length(scaledUV) + center;

        // 3. SECONDARY GLITCH WARP
        // Add a localized ripple warp driven directly by the historical bass
        finalUV.x += sin(finalUV.y * 20.0 + time_f * 5.0 - gen) * histLow * 0.02;
        finalUV.y += cos(finalUV.x * 20.0 + time_f * 4.0 - gen) * histLow * 0.02;

        vec4 cached = sampleCache(i, finalUV);
        
        // 4. CHROMATIC SEPARATION
        // Tear the colors apart on older frames based on the historical bass hit
        if (i > 0) {
            float chroma = histLow * gen * 0.005;
            cached.r = sampleCache(i, finalUV + vec2(chroma, 0.0)).r;
            cached.b = sampleCache(i, finalUV - vec2(chroma, 0.0)).b;
            
            // Boost saturation on historical peaks
            cached.rgb *= 1.0 + (histLow * 0.2);
        }

        // Calculate decay weight, allowing historically loud frames to persist longer in the cache
        float weight = pow(0.75 + (histLow * 0.1), gen);
        accum += cached * weight;
        weightSum += weight;
    }

    color = vec4(clamp(accum / weightSum, 0.0, 1.0).rgb, 1.0);
}