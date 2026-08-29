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
