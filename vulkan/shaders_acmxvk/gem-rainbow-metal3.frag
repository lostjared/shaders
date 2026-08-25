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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;








// High-fidelity spectrum for the oily "fringe" colors
vec3 spectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Ripples driven by bass and treble
    float ripple = sin(angle * 10.0 + time_f) * (0.03 + amp_low * 0.05);
    ripple += sin(angle * 25.0 - time_f * 2.0) * (0.01 + amp_high * 0.03);

    // Radial wave speed and density react to mid energy
    float wave = sin(r * (20.0 + amp_mid * 15.0) - time_f * (4.0 + amp_peak * 3.0) + ripple * 10.0);

    // Chromatic split widens with peak amplitude
    float shift = ripple * 0.5 + wave * 0.01 + amp_peak * 0.015;

    float r_chan = texture(samp, tc + vec2(shift, 0.0)).r;
    float g_chan = texture(samp, tc).g;
    float b_chan = texture(samp, tc - vec2(shift, 0.0)).b;
    vec3 baseTex = vec3(r_chan, g_chan, b_chan);

    // Rainbow hue shifts with smoothed amplitude
    vec3 rainbow = spectrum(r - time_f * 0.5 + ripple + amp_smooth * 0.3);
    float glowMask = smoothstep(0.5, 1.0, wave);

    // Central light expands with amp_rms / amp_smooth
    float lightRadius = 6.0 - amp_smooth * 4.0 - amp_rms * 3.0;
    lightRadius = max(lightRadius, 0.5);
    float center = exp(-r * lightRadius);
    float brightness = 1.5 + amp_peak * 2.0;
    vec3 coreGlow = vec3(1.0, 0.98, 0.9) * center * brightness;

    vec3 finalColor = mix(baseTex, rainbow, glowMask * (0.35 + amp_rms * 0.3));
    finalColor += coreGlow;
    finalColor += (wave * ripple * (2.0 + amp_low * 3.0));

    color = vec4(finalColor, 1.0);
}