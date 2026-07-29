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

// System uniforms
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Audio uniforms
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

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
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aPk  = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);

    vec2 uv = tc - 0.5;

    // Calculate the core drum scale effect
    float drumEffect = aPk * 0.25 + aLow * 0.15;
    float basePulse = 1.0 + drumEffect * sin(time_f * (8.0 + aRms * 12.0));

    // Calculate the drift vector for the mouse interaction
    vec2 drift = vec2(0.0);
    if (iMouse.z > 0.0) {
        vec2 mousePos = iMouse.xy / iResolution.xy;
        // The offset from center. Adding this to the UV pushes the visual texture away.
        drift = (mousePos - 0.5) * 0.15;
    }

    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    for (int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // Modulate the pulse slightly per generation so the trail feels deep
        float layerPulse = basePulse + (gen * 0.015 * aLow);
        vec2 drumUV = uv * layerPulse;
        
        // Multiply the drift by the generation to stretch the trail out over older frames
        drumUV += (drift * gen);
        
        vec4 cached = sampleCache(i, drumUV + 0.5);

        // Older frames fade out, but loud audio keeps the trail visible longer
        float weight = pow(0.75 + (aRms * 0.12), gen);
        
        // Inject a slight chromatic shift on the trailing frames driven by the kick drum
        if (gen > 0.0) {
            cached.r *= 1.0 + (aLow * 0.15 * gen);
            cached.b *= 1.0 + (aPk * 0.1 * gen);
        }

        accum += cached * weight;
        weightSum += weight;
    }

    color = vec4(clamp(accum / weightSum, 0.0, 1.0).rgb, 1.0);
}