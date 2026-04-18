#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

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
