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
    vec2 center = vec2(0.5);
    vec2 dir = tc - center;
    float dist = length(dir);

    // Smooth amp drives radial blur intensity
    float blurStrength = amp_smooth * 0.05 + amp_low * 0.03;
    int samples = 8;
    vec3 col = vec3(0.0);

    for (int i = 0; i < 8; i++) {
        float t = float(i) / float(samples);
        float scale = 1.0 - blurStrength * t;
        vec2 sampleUV = center + dir * scale;
        sampleUV = clamp(sampleUV, 0.0, 1.0);
        col += texture(samp, sampleUV).rgb;
    }
    col /= float(samples);

    // Mids add rotation blur
    float rotBlur = amp_mid * 0.02;
    float angle = atan(dir.y, dir.x);
    vec2 rotUV1 = center + vec2(cos(angle + rotBlur), sin(angle + rotBlur)) * dist;
    vec2 rotUV2 = center + vec2(cos(angle - rotBlur), sin(angle - rotBlur)) * dist;
    vec3 rotCol = (texture(samp, clamp(rotUV1, 0.0, 1.0)).rgb +
                   texture(samp, clamp(rotUV2, 0.0, 1.0)).rgb) * 0.5;
    col = mix(col, rotCol, 0.3);

    // Treble sharpens center (counteracts blur)
    vec3 sharp = texture(samp, tc).rgb;
    float centerWeight = smoothstep(0.5, 0.0, dist) * amp_high;
    col = mix(col, sharp, centerWeight);

    // Peak flash
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
