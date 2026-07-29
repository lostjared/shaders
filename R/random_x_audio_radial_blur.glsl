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
