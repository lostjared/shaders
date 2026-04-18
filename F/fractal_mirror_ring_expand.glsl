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

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

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
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float dist = length(uv - 0.5);
    float ring = sin(dist * 20.0 - t * 4.0 * (1.0 + aLow * 0.5)) * 0.5 + 0.5;
    uv += (uv - 0.5) * ring * 0.2 * aMid;

    float zoom = 1.4 + 0.4 * aLow;
    uv = fractalFold(uv, zoom, t, ctr, aspect, 5);
    uv = mirror(uv);

    float ringGlow = smoothstep(0.02, 0.0, abs(dist - 0.3 - 0.1 * sin(t * 2.0)));
    vec4 tex = texture(samp, uv);
    tex.rgb += ringGlow * vec3(0.0, aHigh * 0.8, 1.0) * 0.5;
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
