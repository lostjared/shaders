#version 330 core

in vec2 tc;
out vec4 color;

// Live feed only
uniform sampler2D samp;

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

void main(void) {
    // Center of the drum strike
    vec2 center = (iMouse.z > 0.0) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    vec2 d = tc - center;
    float r = length(d);
    vec2 dir = d / max(r, 1e-6);

    // Audio mechanics for an extreme drum strike
    // Multiplying the low-end heavily to snap the texture on kick drums
    float strikeForce = (amp_low * 2.5) + (amp_peak * 1.5);
    
    // Dynamic wave density and speed based on mid/high frequencies
    float waveDensity = 12.0 + (amp_mid * 8.0); 
    float speed = 15.0 + (amp_high * 25.0);

    // Sample the FFT to add sharp micro-vibrations directly to the ripple wave
    float bandFFT = texture(spectrum0, clamp(r, 0.0, 1.0)).r;
    
    // Calculate the physical ripple
    float ripple = sin((r * waveDensity - time_f * speed) * 6.2831853);
    
    // Massive amplitude spike on bass hits, focusing the energy near the center strike point
    float amplitude = (0.02 + strikeForce * 0.35) * exp(-r * 3.0); 
    
    // Displace the UVs outward from the strike point
    vec2 uv = tc + dir * ripple * amplitude * (1.0 + bandFFT * 2.0);
    
    // Chromatic aberration tearing based on the impact force
    float chroma = strikeForce * 0.08 * ripple;
    
    vec3 finalColor;
    finalColor.r = texture(samp, uv + dir * chroma).r;
    finalColor.g = texture(samp, uv).g;
    finalColor.b = texture(samp, uv - dir * chroma).b;

    // Flash the impact point on absolute peaks
    finalColor += vec3(0.15, 0.3, 0.4) * strikeForce * exp(-r * 6.0) * max(ripple, 0.0);

    color = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}