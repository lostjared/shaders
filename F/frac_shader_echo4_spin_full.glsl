#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame;
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;

const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect, float spin) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x) + spin;
    float rad = length(p);
    float stepA = 6.28318530718 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 6; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.15, 0.75);
    vec3 blue = vec3(0.10, 0.55, 1.0);
    vec3 green = vec3(0.10, 1.00, 0.45);
    float ph = fract(t * 0.05);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3) * 1.05;
}

void main(void) {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 m = (iMouse.z > 0.5 ? (iMouse.xy / iResolution) : vec2(0.5));

    float t = time_f + iTime;
    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);

    float seg = 4.0 + 2.0 * sin(t * 0.25);
    float zoom = 1.45 + 0.45 * sin(t * 0.35 + 0.2 * sr);
    float kaleidoSpin = t * 0.5 + aMix * 0.05;

    vec2 kUV = reflectUV(tc, seg, m, ar.x, kaleidoSpin);
    kUV = fractalFold(kUV, zoom, t, m, ar.x);

    float radial = length((kUV - m) * ar);
    float globalSpin = t * 0.6;
    kUV = rotateUV(kUV, globalSpin + radial * 4.0, m, ar.x);

    vec2 dir = (kUV - m) * ar;
    float r = length(dir);
    float ripple = sin(20.0 * r - t * 9.0) * 0.012 / (1.0 + 18.0 * r);
    ripple *= 1.0 / (1.0 + 12.0 * (abs(dFdx(r)) + abs(dFdy(r))));

    vec2 uA = kUV + normalize(dir + 1e-5) * ripple;
    vec2 uB = mix(tc, kUV, 0.88);
    vec2 uC = mix(tc, kUV, 0.94) + vec2(0.002 * sin(t), 0.002 * cos(t));

    vec4 t1 = textureGrad(samp, fract(uA), dFdx(uA), dFdy(uA));
    vec4 t2 = textureGrad(samp, fract(uB), dFdx(uB), dFdy(uB));
    vec4 t3 = textureGrad(samp, fract(uC), dFdx(uC), dFdy(uC));

    float hueBase = fract(t * 0.06);
    float sat = 0.8;
    float val = 0.75 + 0.25 * sin(t * 0.5 + dot(tc, vec2(2.3, 1.9)));
    vec3 tint = hsv2rgb(vec3(hueBase + r * 0.25, sat, val));

    float mix1 = 0.5 + 0.5 * sin(t * 0.6);
    float mix2 = 0.5 + 0.5 * cos(t * 0.45);

    vec3 warpCol = mix(sin(t1.rgb * 5.0), sin(t2.rgb * 4.0), mix1);
    warpCol = mix(warpCol, t3.rgb, mix2 * 0.5);
    warpCol *= tint;

    warpCol = pow(max(warpCol, 0.0), vec3(0.85)) * 1.8;

    vec2 dtx = dFdx(tc);
    vec2 dty = dFdy(tc);
    vec3 base = textureGrad(samp, tc, dtx, dty).rgb;

    vec4 s1 = textureGrad(samp, tc, dtx, dty);
    vec4 s2 = textureGrad(samp, tc * 0.5, dtx * 0.5, dty * 0.5);
    vec4 s3 = textureGrad(samp, tc * 0.25, dtx * 0.25, dty * 0.25);
    vec4 s4 = textureGrad(samp, tc * 0.125, dtx * 0.125, dty * 0.125);
    vec3 multi = (s1.rgb + s2.rgb + s3.rgb + s4.rgb) * 0.25;

    vec3 multiBlend = mix(base, multi, 0.7);
    vec3 pattern = mix(warpCol, multiBlend, 0.35);

    pattern *= 1.7;

    float PATTERN_ALPHA = 0.8;
    float BASE_ALPHA = 0.2;

    vec3 combined = base * BASE_ALPHA + pattern * PATTERN_ALPHA;

    vec3 bloom = combined * combined * 0.25 + pow(max(combined - 0.5, 0.0), vec3(3.0)) * 0.22;
    combined += bloom;

    combined = clamp(combined, vec3(0.0), vec3(1.0));
    color = vec4(combined, 1.0);
}
