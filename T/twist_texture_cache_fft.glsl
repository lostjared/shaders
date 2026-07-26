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