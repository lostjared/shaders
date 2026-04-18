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
    vec2 center = vec2(0.5);
    vec2 dir = normalize(tc - center + 0.001);

    // Treble drives chromatic separation distance
    float chromaDist = amp_high * 0.04 + amp_peak * 0.02;

    // Bass wobbles the direction
    float wobble = amp_low * 0.5 * sin(time_f * 3.0 + length(tc - center) * 20.0);
    float c = cos(wobble), s = sin(wobble);
    dir = vec2(c * dir.x - s * dir.y, s * dir.x + c * dir.y);

    float r = texture(samp, clamp(tc + dir * chromaDist, 0.0, 1.0)).r;
    float g = texture(samp, clamp(tc, 0.0, 1.0)).g;
    float b = texture(samp, clamp(tc - dir * chromaDist, 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Mids add a pulsing radial offset
    float radPulse = amp_mid * sin(length(tc - center) * 30.0 - time_f * 5.0) * 0.02;
    vec3 col2 = texture(samp, clamp(tc + dir * radPulse, 0.0, 1.0)).rgb;
    col = mix(col, col2, 0.3);

    // Smooth amp global glow
    col *= 1.0 + amp_smooth * 0.3;

    // Peak brightness
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
