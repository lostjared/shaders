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

const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
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
    float aSmooth = clamp(amp_smooth, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);
    vec2 ar = vec2(aspect, 1.0);

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float zoom = 1.4 + 0.5 * aLow;
    uv = fractalFold(uv, zoom, t, ctr, aspect, 6);

    vec2 p = (uv - ctr) * ar;
    float rD = length(p) + 1e-6;
    float ang = atan(p.y, p.x);
    ang += 0.5 * sin(rD * 10.0 + t * 0.8) * aPk;

    float base_ = 1.8 + 0.2 * pingPong(t * 0.2, 5.0);
    float period = log(base_) * pingPong(t * PI, 5.0);
    float k = fract((log(rD) - t * 0.5) / max(period, 0.01));
    float rw = exp(k * max(period, 0.01));
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;
    vec2 logUV = fract(pwrap / ar + ctr);
    logUV = 1.0 - abs(1.0 - 2.0 * logUV);

    float chromaStr = 0.004 + 0.008 * aPk;
    vec2 dir = normalize(pwrap + 1e-5) * chromaStr * vec2(1.0, 1.0 / aspect);
    vec3 rC = texture(samp, fract(logUV + dir)).rgb;
    vec3 gC = texture(samp, logUV).rgb;
    vec3 bC = texture(samp, fract(logUV - dir)).rgb;
    vec3 col = vec3(rC.r, gC.g, bC.b);

    float vign = 1.0 - smoothstep(0.6, 1.2, length((tc - ctr) * ar));
    col *= mix(0.85, 1.15 + aSmooth * 0.2, vign);
    col *= 1.0 + aPk * 0.6;
    col = mix(col, col * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
