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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

// Live feed only
layout(set = 0, binding = 0) uniform sampler2D samp;

// Audio and core uniforms








layout(set = 0, binding = 3) uniform sampler1D spectrum0;

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