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

vec3 spectrum(float w) {
    vec3 c;
    if (w < 0.25)
        c = mix(vec3(0.5, 0.0, 1.0), vec3(0.0, 0.0, 1.0), w * 4.0);
    else if (w < 0.5)
        c = mix(vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0), (w - 0.25) * 4.0);
    else if (w < 0.75)
        c = mix(vec3(0.0, 1.0, 0.0), vec3(1.0, 1.0, 0.0), (w - 0.5) * 4.0);
    else
        c = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), (w - 0.75) * 4.0);
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
