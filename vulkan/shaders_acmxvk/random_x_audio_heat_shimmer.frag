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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










void main(void) {
    vec2 uv = tc;

    // Mids drive shimmer frequency and amplitude
    float freq = 40.0 + amp_mid * 80.0;
    float strength = 0.005 + amp_mid * 0.02;

    // Horizontal heat distortion
    float shimmerX = sin(uv.y * freq + time_f * (3.0 + amp_low * 5.0)) * strength;
    float shimmerY = cos(uv.x * freq * 0.7 + time_f * (2.5 + amp_low * 4.0)) * strength * 0.5;

    uv.x += shimmerX;
    uv.y += shimmerY;

    // Bass adds slow large-scale warp
    uv.x += amp_low * 0.02 * sin(uv.y * 5.0 + time_f);
    uv.y += amp_low * 0.015 * cos(uv.x * 4.0 + time_f * 0.8);

    vec4 tex = texture(samp, clamp(uv, 0.0, 1.0));

    // Treble adds warm color shift (heat effect)
    tex.r += amp_high * 0.08;
    tex.g += amp_high * 0.03;
    tex.b -= amp_high * 0.05;

    // RMS brightens the scene (hotter = brighter)
    tex.rgb *= 1.0 + amp_rms * 0.4;

    // Smooth vignette
    float dist = length(tc - 0.5);
    float vign = smoothstep(0.8, 0.3, dist);
    tex.rgb *= mix(0.7, 1.0, vign);

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.15;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
