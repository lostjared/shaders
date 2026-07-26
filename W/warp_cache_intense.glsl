#version 330 core

in vec2 tc;
out vec4 color;

// Live feed and 8-frame cache layers
uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

// Historical FFT data (0 is now, 7 is oldest)
uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

// System uniforms
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Audio uniforms
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

// Helper to fetch history frames
vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp, uv);
    if (idx == 1) return texture(samp1, uv);
    if (idx == 2) return texture(samp2, uv);
    if (idx == 3) return texture(samp3, uv);
    if (idx == 4) return texture(samp4, uv);
    if (idx == 5) return texture(samp5, uv);
    if (idx == 6) return texture(samp6, uv);
    if (idx == 7) return texture(samp7, uv);
    return texture(samp8, uv);
}

// Helper to fetch historical FFT data
float sampleSpectrumHistory(int idx, float freq) {
    if (idx <= 0) return texture(spectrum0, freq).r;
    if (idx == 1) return texture(spectrum1, freq).r;
    if (idx == 2) return texture(spectrum2, freq).r;
    if (idx == 3) return texture(spectrum3, freq).r;
    if (idx == 4) return texture(spectrum4, freq).r;
    if (idx == 5) return texture(spectrum5, freq).r;
    if (idx == 6) return texture(spectrum6, freq).r;
    return texture(spectrum7, freq).r;
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

    // 1. EXPANSION (3x Intense)
    // Base expansion force driven by live low frequencies, multiplied by 3
    float baseExpansion = 1.0 - (amp_low * 0.45);
    
    for (int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // Map the texture history index directly to the FFT history array
        int historyIdx = min(i, 7); 
        
        // Fetch historical low and high frequencies for this specific frame
        float histLow = sampleSpectrumHistory(historyIdx, 0.05);
        float histHigh = sampleSpectrumHistory(historyIdx, 0.75);

        // Scale UVs outward over time. Historical low multiplier increased to 0.15.
        float expansionFactor = pow(baseExpansion - (histLow * 0.15), gen);
        vec2 scaledUV = uv_centered * expansionFactor;

        // 2. WARP (3x Intense)
        // Twist based on historical high frequencies. Multipliers boosted significantly.
        float warpIntensity = (histHigh * 1.5) + (amp_peak * 0.6);
        float warpAngle = angle + (sin(radius * 10.0 - time_f * 2.0) * warpIntensity * gen * 0.1);
        
        // Reconstruct UV coordinates after polar expansion and warping
        vec2 finalUV = vec2(cos(warpAngle), sin(warpAngle)) * length(scaledUV) + center;

        // 3. SECONDARY GLITCH WARP (3x Intense)
        // Add a localized ripple warp driven directly by the historical bass, increased to 0.06
        finalUV.x += sin(finalUV.y * 20.0 + time_f * 5.0 - gen) * histLow * 0.06;
        finalUV.y += cos(finalUV.x * 20.0 + time_f * 4.0 - gen) * histLow * 0.06;

        vec4 cached = sampleCache(i, finalUV);
        
        // 4. CHROMATIC SEPARATION
        if (i > 0) {
            // Scaled the chromatic tear up slightly to match the more intense physical movement
            float chroma = histLow * gen * 0.015;
            cached.r = sampleCache(i, finalUV + vec2(chroma, 0.0)).r;
            cached.b = sampleCache(i, finalUV - vec2(chroma, 0.0)).b;
            
            // Boost saturation on historical peaks
            cached.rgb *= 1.0 + (histLow * 0.2);
        }

        // Calculate decay weight
        float weight = pow(0.75 + (histLow * 0.1), gen);
        accum += cached * weight;
        weightSum += weight;
    }

    color = vec4(clamp(accum / weightSum, 0.0, 1.0).rgb, 1.0);
}