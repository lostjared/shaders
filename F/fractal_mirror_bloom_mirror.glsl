#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_rms;

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect, int iters) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aSmooth = clamp(amp_smooth, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float zoom = 1.4 + 0.4 * aLow;
    uv = fractalFold(uv, zoom, t, ctr, aspect, 5);
    uv = 1.0 - abs(1.0 - 2.0 * fract(uv));

    vec4 tex = texture(samp, uv);

    vec3 bloom = tex.rgb * tex.rgb * 0.2 + pow(max(tex.rgb - 0.6, 0.0), vec3(2.0)) * 0.15;
    bloom *= 1.0 + aPk * 1.5;
    tex.rgb += bloom;

    float vign = 1.0 - smoothstep(0.5, 1.0, length((tc - 0.5) * vec2(aspect, 1.0)));
    tex.rgb *= mix(0.85, 1.15 + aSmooth * 0.2, vign);
    tex.rgb *= 1.0 + aPk * 0.4;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
