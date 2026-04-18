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

vec2 mirrorFold(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // RMS controls fold count (2 to 8 folds)
    float foldCount = 2.0 + amp_rms * 6.0;
    float segAngle = 6.28318 / foldCount;
    float angle = atan(uv.y, uv.x);
    float dist = length(uv);
    angle = mod(angle, segAngle);
    angle = abs(angle - segAngle * 0.5);

    // Mids rotate the fold pattern
    angle += time_f * (0.2 + amp_mid * 1.5);

    vec2 folded = vec2(cos(angle), sin(angle)) * dist;
    folded.x /= aspect;
    folded += 0.5;

    // Bass adds recursive fold depth
    for (int i = 0; i < 3; i++) {
        if (amp_low > 0.1 * float(i + 1)) {
            folded = mirrorFold(folded * (1.2 + amp_low * 0.3));
        }
    }

    // Smooth drift
    folded += amp_smooth * 0.05 * vec2(sin(time_f * 0.7), cos(time_f * 0.5));

    vec4 tex = texture(samp, clamp(folded, 0.0, 1.0));

    // Treble color accent
    tex.r += amp_high * 0.06;
    tex.b += amp_high * 0.04;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = tex;
}
