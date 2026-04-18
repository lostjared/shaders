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

    float seg = 8.0 + 4.0 * aMid;
    vec2 uv = reflectUV(tc, seg, ctr, aspect);
    float zoom = 1.5 + 0.5 * aLow;
    uv = fractalFold(uv, zoom, t, ctr, aspect, 6);
    uv = mirror(uv);

    float chromaStr = 0.004 + 0.008 * aPk;
    vec2 dir = normalize(uv - 0.5 + 1e-5);
    vec2 off = dir * chromaStr;

    vec3 rC = texture(samp, fract(uv + off)).rgb;
    vec3 gC = texture(samp, fract(uv)).rgb;
    vec3 bC = texture(samp, fract(uv - off)).rgb;
    vec3 col = vec3(rC.r, gC.g, bC.b);

    col *= 1.0 + aPk * 0.6;
    col = mix(col, col * vec3(1.0 + aLow * 0.3, 1.0 - aLow * 0.1, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
