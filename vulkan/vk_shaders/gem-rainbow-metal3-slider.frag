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
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define slider1 ext.custom_uniforms[5].x
#define slider2 ext.custom_uniforms[5].y
#define slider3 ext.custom_uniforms[5].z
#define slider4 ext.custom_uniforms[5].w
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;


// Audio variables








// New MIDI/Audio Uniforms
layout(set = 0, binding = 3) uniform sampler1D spectrum; // 1D FFT audio data





// Renamed from 'spectrum' to avoid sampler1D collision
vec3 colorPalette(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

// Fetch FFT data using the normalized radius. 
    float fft = texture(spectrum, clamp(r * 0.5, 0.0, 1.0)).r;

    // FIX: Force lobes to be a whole number so the circle completes seamlessly
    float lobes = floor(mix(2.0, 40.0, slider1));
    
    float ripple = sin(angle * lobes + time_f) * (0.03 + amp_low * 0.05);
    
    // FIX: Also ensure the secondary ripple uses a whole number!
    // (lobes * 2.5) could result in a fraction like 27.5, which would cause a seam.
    float secondaryLobes = floor(lobes * 2.5);
    ripple += sin(angle * secondaryLobes - time_f * 2.0) * (0.01 + amp_high * 0.03);

    // SLIDER 2: Radial wave density (maps 0.0-1.0 to 5.0-50.0)
    // (Density doesn't rely on 'angle', so it can safely remain fractional)
    float waveDensity = mix(5.0, 50.0, slider2);
    
    // Inject FFT data into the wave calculation, scaled by SLIDER 4
    float wave = sin(r * (waveDensity + amp_mid * 15.0) - time_f * (4.0 + amp_peak * 3.0) + ripple * 10.0 + (fft * 10.0 * slider4));

    // SLIDER 3: Chromatic shift multiplier (maps 0.0-1.0 to 0.1-5.0)
    float shiftMult = mix(0.1, 5.0, slider3);
    float shift = (ripple * 0.5 + wave * 0.01 + amp_peak * 0.015) * shiftMult;

    // Chromatic split sampling
    float r_chan = texture(samp, tc + vec2(shift, 0.0)).r;
    float g_chan = texture(samp, tc).g;
    float b_chan = texture(samp, tc - vec2(shift, 0.0)).b;
    vec3 baseTex = vec3(r_chan, g_chan, b_chan);

    // Rainbow hue shifts with smoothed amplitude and FFT data
    vec3 rainbow = colorPalette(r - time_f * 0.5 + ripple + amp_smooth * 0.3 + (fft * slider4));
    float glowMask = smoothstep(0.5, 1.0, wave);

    // Central light expands with amp_rms / amp_smooth
    float lightRadius = 6.0 - amp_smooth * 4.0 - amp_rms * 3.0;
    lightRadius = max(lightRadius, 0.5);
    float center = exp(-r * lightRadius);
    float brightness = 1.5 + amp_peak * 2.0;
    vec3 coreGlow = vec3(1.0, 0.98, 0.9) * center * brightness;

    // Mix base texture with rainbow, using SLIDER 4 to boost FFT glow
    vec3 finalColor = mix(baseTex, rainbow, glowMask * (0.35 + amp_rms * 0.3 + (fft * 0.5 * slider4)));
    finalColor += coreGlow;
    
    // Add the glitchy wave feedback
    finalColor += (wave * ripple * (2.0 + amp_low * 3.0));

    color = vec4(finalColor, 1.0);
}