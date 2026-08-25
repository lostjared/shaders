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










vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.25) c = mix(vec3(0.5, 0.0, 1.0), vec3(0.0, 0.0, 1.0), w * 4.0);
    else if (w < 0.5) c = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), (w - 0.25) * 4.0);
    else if (w < 0.75) c = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (w - 0.5) * 4.0);
    else c = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (w - 0.75) * 4.0);
    return c;
}

void main(void) {
    vec2 p = (tc - 0.5) * iResolution.xy / iResolution.y;

    // RMS scales dispersion amount
    float dispersion = 0.03 + amp_rms * 0.12;

    // Bass warps the direction
    vec2 dir = normalize(p + 0.001);
    dir += amp_low * 0.5 * vec2(sin(time_f * 2.0), cos(time_f * 1.7));
    dir = normalize(dir);

    int samples = 8;
    vec3 accum = vec3(0.0);

    for (int i = 0; i < samples; i++) {
        float w = float(i) / float(samples - 1);
        float shift = (w - 0.5) * dispersion;
        vec2 sampleUV = tc + dir * shift;
        sampleUV = clamp(sampleUV, 0.0, 1.0);

        vec3 spec = spectrum(w);
        accum += texture(samp, sampleUV).rgb * spec;
    }

    vec3 col = accum / float(samples) * 2.0;

    // Mids add rotation to the dispersion field
    float midPulse = amp_mid * sin(length(p) * 10.0 - time_f * 3.0) * 0.1;
    col += midPulse;

    // Peak shatter flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.25;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
