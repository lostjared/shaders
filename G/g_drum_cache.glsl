#version 330 core

in vec2 tc;
out vec4 color;

// Live feed and 8-frame cache layers
uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

// Audio and core uniforms
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform sampler1D spectrum0;

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
    // Center of the drum strike
    vec2 center = (iMouse.z > 0.0) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    vec2 d = tc - center;
    float r = length(d);
    vec2 dir = d / max(r, 1e-6);

    // Audio mechanics for the drum strike
    float strikeForce = amp_low + (amp_peak * 0.5);
    float waveDensity = 20.0 + (amp_mid * 10.0); // Simulates the tension of the drum skin
    float speed = 5.0 + (amp_high * 15.0);

    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    for (int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // Time offset creates the temporal vibration, pushing the wave out through the cache
        float timeOffset = time_f - (gen * 0.04);
        
        // Sample the FFT to add micro-vibrations to the main drum ripple
        float bandFFT = texture(spectrum0, clamp(r + gen * 0.1, 0.0, 1.0)).r;
        
        // Calculate the physical ripple
        float ripple = sin((r * waveDensity - timeOffset * speed) * 6.2831853);
        
        // The amplitude decays in older frames, simulating the resonance fading
        float amplitude = (0.01 + strikeForce * 0.15) * pow(0.75, gen);
        
        // Displace the UVs outward from the strike point
        vec2 uv = tc + dir * ripple * amplitude * (1.0 + bandFFT);
        
        vec4 cached = sampleCache(i, uv);
        
        // Add impact glitching: Hard strikes cause older echoes to separate chromatically
        if (gen > 0.0) {
            cached.r *= 1.0 + (strikeForce * 0.15 * (gen * 0.1));
            cached.b *= 1.0 + (bandFFT * 0.4);
        }

        // Smoother audio creates a longer resonant tail in the feedback loop
        float weight = pow(0.80 + (amp_smooth * 0.15), gen);
        
        accum += cached * weight;
        weightSum += weight;
    }

    // Output the stabilized resonance
    color = clamp(accum / weightSum, 0.0, 1.0);
}