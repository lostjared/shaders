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

const float TAU = 6.28318530718;

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float step_ = TAU / segments;
    ang = mod(ang, step_);
    ang = abs(ang - step_ * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
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

    float seg1 = 6.0 + 2.0 * aLow;
    vec2 uv1 = reflectUV(tc, seg1, ctr, aspect);
    float zoom = 1.4 + 0.4 * aMid;
    uv1 = fractalFold(uv1, zoom, t, ctr, aspect, 4);
    uv1 = 1.0 - abs(1.0 - 2.0 * fract(uv1));

    float seg2 = 8.0 + 2.0 * aHigh;
    vec2 uv2 = reflectUV(tc, seg2, ctr, aspect);
    uv2 = fractalFold(uv2, zoom * 0.8, t * 0.7, ctr, aspect, 3);
    uv2 = 1.0 - abs(1.0 - 2.0 * fract(uv2));

    float dist = length((tc - 0.5) * vec2(aspect, 1.0));
    float mixAmt = smoothstep(0.2, 0.6, dist) + 0.2 * sin(t * 2.0);
    mixAmt = clamp(mixAmt, 0.0, 1.0);

    vec4 t1 = texture(samp, uv1);
    vec4 t2 = texture(samp, uv2);
    vec4 tex = mix(t1, t2, mixAmt);

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
