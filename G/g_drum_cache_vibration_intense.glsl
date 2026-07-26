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
    if (idx == 1) return texture(samp1, uv); 
    if (idx == 2) return texture(samp2, uv);
    if (idx == 3) return texture(samp3, uv);
    if (idx == 4) return texture(samp4, uv);
    if (idx == 5) return texture(samp5, uv);
    if (idx == 6) return texture(samp6, uv);
    if (idx == 7) return texture(samp7, uv);
    return texture(samp8, uv);
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