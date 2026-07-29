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
    vec2 center = (iMouse.z > 0.0) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    vec2 d = tc - center;
    float r = length(d);
    vec2 dir = d / max(r, 1e-6);

    // Audio mechanics for the strike force
    float strikeForce = (amp_low * 2.0) + amp_peak;
    
    vec4 accum = vec4(0.0);
    float weightSum = 0.0;

    for (int i = 0; i <= 8; i++) {
        float gen = float(i);
        
        // 1. Outward Propagation: Older frames have a larger radius
        // This physically pushes the shockwave outward through the cache
        float waveRadius = (gen * 0.06) + (amp_low * 0.05); 
        
        // Distance from the current pixel to this generation's wave front
        float distToWave = abs(r - waveRadius);
        
        // 2. The Shockwave Pulse (Replacing the sine ripple)
        // Using exponential falloff to create a sharp, isolated structural strike
        float pulseSharpness = 40.0 - (amp_mid * 15.0);
        float pulse = exp(-distToWave * pulseSharpness);
        
        // Sample FFT at the location of the wave to get localized frequency data
        float bandFFT = texture(spectrum0, clamp(waveRadius, 0.0, 1.0)).r;
        
        // 3. Membrane Jitter
        // High frequency vibration simulating the physical tension of the surface
        float skinJitter = sin(r * 150.0 - time_f * 25.0) * bandFFT * amp_high;
        
        // Combine the heavy structural pulse with the chaotic high-end jitter
        float displacement = (pulse * strikeForce * 0.15) + (skinJitter * 0.03);
        
        // Decay the power of the displacement as the wave echoes outward
        float amplitude = displacement * pow(0.65, gen);
        
        vec2 uv = tc + dir * amplitude;
        vec4 cached = sampleCache(i, uv);
        
        // 4. Chromatic Impact Tearing on the shockwave ridge
        if (pulse > 0.1 && gen > 0.0) {
            float chromaOffset = pulse * strikeForce * 0.02 * pow(0.8, gen);
            cached.r = sampleCache(i, uv + dir * chromaOffset).r;
            cached.b = sampleCache(i, uv - dir * chromaOffset).b;
            
            // Additive energy flash on the wave crest driven by the FFT
            cached.rgb += vec3(0.2, 0.4, 0.5) * pulse * bandFFT * strikeForce * pow(0.7, gen);
        }
        
        // Accumulate the frames, smoothly fading out the older echoes
        float weight = pow(0.82 + (amp_smooth * 0.1), gen);
        accum += cached * weight;
        weightSum += weight;
    }

    color = vec4(clamp(accum / weightSum, 0.0, 1.0).rgb, 1.0);
}