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
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);

    // Bass spawns outward ripple rings
    float ringSpeed = 4.0 + amp_low * 8.0;
    float ringFreq = 20.0 + amp_low * 30.0;
    float ripple = sin(dist * ringFreq - time_f * ringSpeed) * exp(-dist * 2.0);

    // Mids add angular wobble to the rings
    float angle = atan(uv.y, uv.x);
    ripple += amp_mid * 0.3 * sin(angle * 4.0 + time_f * 2.0) * exp(-dist * 3.0);

    // Apply ripple displacement
    float displacement = ripple * (0.02 + amp_peak * 0.04);
    vec2 rippleUV = tc + normalize(uv + 0.001) * displacement;
    rippleUV = clamp(rippleUV, 0.0, 1.0);

    vec4 tex = texture(samp, rippleUV);

    // Treble adds bright ring outlines
    float ringLine = abs(sin(dist * ringFreq * 0.5 - time_f * ringSpeed * 0.5));
    ringLine = smoothstep(0.95, 1.0, ringLine) * amp_high * 0.5;
    tex.rgb += ringLine * vec3(0.5, 0.8, 1.0);

    // RMS brightness
    tex.rgb *= 1.0 + amp_rms * 0.3;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = tex;
}
