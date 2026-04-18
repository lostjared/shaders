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
    vec2 centered = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(centered);
    float theta = atan(centered.y, centered.x);

    // Bass + mids drive twist amount
    float twistAmt = 10.0 + amp_low * 25.0 + amp_mid * 15.0;
    float twistSpeed = sin(time_f * (0.5 + amp_mid * 2.0));
    theta += (1.0 - r) * twistAmt * twistSpeed;

    // Peak adds sudden extra twist
    theta += amp_peak * 5.0 * sin(r * 10.0);

    vec2 twisted = vec2(cos(theta), sin(theta)) * r;
    twisted.x /= aspect;
    twisted += 0.5;

    // Wrap
    twisted = abs(mod(twisted, 2.0) - 1.0);

    vec4 tex = texture(samp, clamp(twisted, 0.0, 1.0));

    // Treble adds neon tint
    float neon = amp_high * sin(theta * 3.0 + time_f * 2.0) * 0.2;
    tex.r += neon;
    tex.b += neon * 0.5;

    // RMS brightness boost
    tex.rgb *= 1.0 + amp_rms * 0.4;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
