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

vec2 mirror(vec2 uv) {
    vec2 w = abs(fract(uv * 0.5 + 0.5) * 2.0 - 1.0);
    return clamp(w, 0.0, 1.0);
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

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
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
        float z = zoom + 0.10 * sin(t * 0.20 + float(i) * 0.7);
        p = abs((p - c) * z) - 0.5 + c;
        p = rotateUV(p, t * 0.10 + float(i) * 0.06, c, aspect);
    }
    return p;
}

vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.15, 0.75);
    vec3 blue = vec3(0.10, 0.55, 1.0);
    vec3 green = vec3(0.10, 1.00, 0.45);
    float ph = fract(t * 0.04);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3) * 1.02;
}

vec3 softTone(vec3 c) {
    c = pow(max(c, 0.0), vec3(0.96));
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, 0.9);
    return clamp(c, 0.0, 1.0);
}

vec3 tentBlur3(sampler2D img, vec2 uv, vec2 res) {
    vec2 ts = 1.0 / res;
    vec3 s00 = textureGrad(img, uv + ts * vec2(-1.0, -1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s10 = textureGrad(img, uv + ts * vec2(0.0, -1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s20 = textureGrad(img, uv + ts * vec2(1.0, -1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s01 = textureGrad(img, uv + ts * vec2(-1.0, 0.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s11 = textureGrad(img, uv, dFdx(uv), dFdy(uv)).rgb;
    vec3 s21 = textureGrad(img, uv + ts * vec2(1.0, 0.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s02 = textureGrad(img, uv + ts * vec2(-1.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s12 = textureGrad(img, uv + ts * vec2(0.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s22 = textureGrad(img, uv + ts * vec2(1.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    return (s00 + 2.0 * s10 + s20 + 2.0 * s01 + 4.0 * s11 + 2.0 * s21 + s02 + 2.0 * s12 + s22) / 16.0;
}

vec3 preBlendColor(vec2 uv, float t, float sr) {
    vec3 tex = tentBlur3(samp, uv, iResolution);
    vec2 gdir = normalize(vec2(cos(t * 0.18 + 0.3 * sr), sin(t * 0.20 - 0.3 * sr)));
    float s = dot((uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0), gdir);
    float w = max(fwidth(s) * 6.0, 0.003);
    float band = smoothstep(-0.5 - w, -0.5 + w, sin(s * 1.6 + t * 0.6));
    vec3 neon = neonPalette(t);
    vec3 grad = mix(tex, mix(tex, neon, 0.55), 0.30 + 0.20 * band);
    grad = mix(grad, tex, 0.12);
    grad = softTone(grad);
    return grad;
}

float diamondRadius(vec2 p) {
    p = sin(abs(p));
    return max(p.x, p.y);
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;
    p.x /= aspect;
    return p + c;
}

vec2 wormholeUV(vec2 uv, vec2 c, float aspect, float t) {
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - c) * ar;
    float r = length(p) + 1e-6;
    float a = atan(p.y, p.x);
    float swirl = 0.18 / r;
    a += t * 0.25 + swirl;
    float z = 0.55 + 0.30 * sin(t * 0.45) + 0.10 * sin(r * 9.0 - t * 2.0);
    float rr = 1.0 / (r * 3.2 + 0.08) + 0.06 * z;
    vec2 q = vec2(cos(a), sin(a)) * rr;
    q /= ar;
    return mirror(q + c);
}

float sceneLuma() {
    vec3 s0 = texture(samp, vec2(0.25, 0.25)).rgb;
    vec3 s1 = texture(samp, vec2(0.50, 0.25)).rgb;
    vec3 s2 = texture(samp, vec2(0.75, 0.25)).rgb;
    vec3 s3 = texture(samp, vec2(0.25, 0.50)).rgb;
    vec3 s4 = texture(samp, vec2(0.50, 0.50)).rgb;
    vec3 s5 = texture(samp, vec2(0.75, 0.50)).rgb;
    vec3 s6 = texture(samp, vec2(0.25, 0.75)).rgb;
    vec3 s7 = texture(samp, vec2(0.50, 0.75)).rgb;
    vec3 s8 = texture(samp, vec2(0.75, 0.75)).rgb;
    float L = 0.0;
    L += dot(s0, vec3(0.299, 0.587, 0.114));
    L += dot(s1, vec3(0.299, 0.587, 0.114));
    L += dot(s2, vec3(0.299, 0.587, 0.114));
    L += dot(s3, vec3(0.299, 0.587, 0.114));
    L += dot(s4, vec3(0.299, 0.587, 0.114));
    L += dot(s5, vec3(0.299, 0.587, 0.114));
    L += dot(s6, vec3(0.299, 0.587, 0.114));
    L += dot(s7, vec3(0.299, 0.587, 0.114));
    L += dot(s8, vec3(0.299, 0.587, 0.114));
    return L / 9.0;
}

vec3 toneDownWhite(vec3 c) {
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float factor = smoothstep(0.6, 1.0, lum);
    c = mix(c, c * 0.7, factor);
    c = pow(c, vec3(0.95 + 0.05 * (1.0 - factor)));
    return clamp(c, 0.0, 1.0);
}

void main(void) {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 m = (iMouse.z > 0.5 ? (iMouse.xy / iResolution) : vec2(0.5));
    float t = time_f + iTime;
    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);

    float seg = 4.0 + 2.0 * sin(t * 0.20 + 0.25 * aMix);
    float zoom = 1.45 + 0.40 * sin(t * 0.28 + 0.15 * sr);

    vec2 kUV = reflectUV(tc, seg, m, ar.x);
    kUV = fractalFold(kUV, zoom, t, m, ar.x);
    kUV = rotateUV(kUV, t * 0.18, m, ar.x);
    kUV = diamondFold(kUV, m, ar.x);

    vec2 dir = (kUV - m) * ar;
    float r = length(dir);
    float ripple = sin(14.0 * r - t * 5.0) * 0.008 / (1.0 + 12.0 * r);
    ripple *= 1.0 / (1.0 + 10.0 * (abs(dFdx(r)) + abs(dFdy(r))));
    vec2 uA = kUV + normalize(dir + 1e-5) * ripple;
    vec2 uB = mix(tc, kUV, 0.82);
    vec2 uC = mix(tc, kUV, 0.90) + vec2(0.0015 * sin(t * 0.8), 0.0015 * cos(t * 0.8));

    vec2 sA = mirror(uA);
    vec2 sB = mirror(uB);
    vec2 sC = mirror(uC);

    vec4 t1 = textureGrad(samp, sA, dFdx(sA), dFdy(sA));
    vec4 t2 = textureGrad(samp, sB, dFdx(sB), dFdy(sB));
    vec4 t3 = textureGrad(samp, sC, dFdx(sC), dFdy(sC));

    vec3 warpCol = mix(t1.rgb, t2.rgb, 0.5 + 0.5 * sin(t * 0.45));
    warpCol = mix(warpCol, t3.rgb, 0.25 + 0.25 * cos(t * 0.33));

    float sat = 0.72 + 0.22 * sin(t * 0.32 + sr);
    float val = 0.62 + 0.30 * sin(t * 0.36 + dot(tc, vec2(2.1, 1.7)));
    vec3 tint = hsv2rgb(vec3(fract(t * 0.045) + r * 0.20, sat, val));
    warpCol *= tint * (0.94 + 0.06 * (0.5 + 0.5 * sin(t * 0.6 + aMix * 0.04)));

    vec3 baseTex = textureGrad(samp, tc, dFdx(tc), dFdy(tc)).rgb;
    vec3 preK = preBlendColor(mirror(kUV), t, sr);

    vec2 wh0 = wormholeUV(tc, m, ar.x, t);
    vec2 wh1 = wormholeUV(tc + vec2(0.0009, 0.0), m, ar.x, t + 0.02);
    vec2 wh2 = wormholeUV(tc - vec2(0.0009, 0.0), m, ar.x, t - 0.02);
    vec2 off = normalize(dir + 1e-5) * (0.0012 + 0.0008 * sin(t * 0.9)) * vec2(1.0, 1.0 / ar.x);

    vec3 whR = preBlendColor(mirror(wh0 + off), t, sr);
    vec3 whG = preBlendColor(mirror(wh1), t, sr);
    vec3 whB = preBlendColor(mirror(wh2 - off), t, sr);
    vec3 wormRGB = vec3(sin(whR.r * pingPong(t * PI, 1.1)),
                        sin(whG.g * pingPong(t * PI, 1.2)),
                        sin(whB.b * pingPong(t * PI, 1.3)));

    float rCenter = length((tc - m) * ar);
    float throatBase = smoothstep(0.45, 0.10, rCenter);
    float throat = mix(throatBase, throatBase * throatBase, 0.5) * (0.55 + 0.45 * sin(t * 0.35));
    float swirlGate = smoothstep(0.8, 1.6, t * 0.18 + 0.25 * sin(t * 0.5));
    float gateRaw = throat * (0.55 + 0.35 * pingPong(t * PI, 3.0)) + swirlGate * 0.12;
    float wGate = max(fwidth(gateRaw) * 2.0, 0.002);
    float gate = smoothstep(0.0, 1.0, clamp(gateRaw, 0.0, 1.0));
    gate = smoothstep(0.0, 1.0, mix(gate, gate, 1.0 - wGate));

    vec3 mixA = mix(preK, warpCol, 0.52);
    vec3 mixB = mix(mixA, wormRGB, gate * 0.72);

    vec3 bloom = mixB * mixB * 0.14 + pow(max(mixB - 0.65, 0.0), vec3(2.0)) * 0.08;
    vec3 combined = mixB + bloom;

    float vign = 1.0 - smoothstep(0.78, 1.10, length((tc - m) * ar));
    combined *= mix(0.96, 1.06, vign);

    float Lscene = sceneLuma();
    float baseFactor = mix(1.0, 0.75, smoothstep(0.55, 0.9, Lscene));
    float finalFactor = mix(1.0, 0.72, smoothstep(0.55, 0.9, Lscene));

    baseTex = toneDownWhite(baseTex) * baseFactor;

    vec3 master = mix(baseTex, combined * 2.6, 0.58) * finalFactor;
    master = clamp(master, vec3(0.03), vec3(0.97));

    color = vec4(master, 1.0);
}
