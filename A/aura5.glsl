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

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 78.233);
    return fract(p.x * p.y);
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
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.15, 0.75);
    vec3 blue = vec3(0.10, 0.55, 1.0);
    vec3 green = vec3(0.10, 1.00, 0.45);
    float ph = fract(t * 0.08);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3) * 1.05;
}

vec3 softTone(vec3 c) {
    c = pow(max(c, 0.0), vec3(0.95));
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

vec3 preBlendColor(vec2 uv, float seed, float drive) {
    vec3 tex = tentBlur3(samp, uv, iResolution);
    vec2 gdir = normalize(vec2(cos(seed * 0.27 + drive), sin(seed * 0.31 - drive)));
    float s = dot((uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0), gdir);
    float w = max(fwidth(s) * (3.0 + drive * 0.5), 0.002);
    float band = smoothstep(-0.5 - w, -0.5 + w, sin(s * (2.2 + drive * 0.6) + seed * 0.9));
    vec3 neon = neonPalette(seed + drive * 0.25);
    vec3 grad = mix(tex, mix(tex, neon, 0.6), 0.35 + 0.25 * band);
    grad = mix(grad, tex, 0.10);
    grad = softTone(grad);
    return grad;
}

float diamondRadius(vec2 p) {
    p = abs(p);
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

vec3 aces(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    x = (x * (a * x + b)) / (x * (c * x + d) + e);
    return clamp(x, 0.0, 1.0);
}

void main(void) {
    vec4 baseTex = texture(samp, tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    float t = time_f + iTime * 0.75;
    float daySeed = iDate.x * 37.0 + iDate.y * 17.0 + iDate.z * 7.0 + iDate.w;
    float seed = t + daySeed * 0.013;
    float fr = max(iFrameRate, 1.0);
    float dt = max(iTimeDelta, 1.0 / fr);
    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);
    float drive = clamp(aMix * 0.08, 0.0, 2.5);
    float segBase = 4.0 + 2.0 * sin(seed * 0.33 + 0.15 * sr);
    segBase += 2.0 * (step(0.5, fract(iMouseClick.x * 0.5 + iMouseClick.y * 0.5))) * sin(seed * 0.5);
    float seg = clamp(segBase + 2.0 * sin(dot(iChannelResolution[0].xy, vec2(0.003, 0.004)) + iChannelTime[0] * 0.23), 3.0, 12.0);
    float zoom = 1.45 + 0.55 * sin(seed * (0.42 + 0.15 * sr)) + 0.25 * sin(iChannelTime[1] * 0.31 + length(iChannelResolution[1].xy) * 0.0007);
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= aspect;
    float beat = 0.5 + 0.5 * sin(t * 3.1 + drive * 6.0);
    float ringR = mix(0.9, 1.4, beat);
    ringR *= 1.0 + 0.3 * sin(iChannelTime[2] * 0.7);
    float r = length(uv);
    float glow = smoothstep(ringR, ringR - 0.25, r);
    vec3 baseCol = preBlendColor(tc, seed, drive);
    vec2 kUV = reflectUV(tc, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    kUV = fractalFold(kUV, zoom, seed, m, aspect);
    kUV = rotateUV(kUV, seed * (0.23 + 0.12 * drive), m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x)
        q = q.yx;
    float base = 1.82 + 0.18 * sin(seed * 0.2);
    float period = log(base);
    float tz = seed * (0.65 + 0.2 * sin(iChannelTime[3] * 0.21));
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + seed * 0.6 + drive * 3.0);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;
    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * (1.03 + 0.02 * drive)) / ar + m);
    vec2 u2 = fract((pwrap * (0.97 - 0.02 * drive)) / ar + m);
    vec2 dir = normalize(pwrap + 1e-6);
    float chroma = (0.0012 + 0.0010 * drive) * (1.0 + 0.3 * sin(seed * 1.7));
    vec2 off = dir * chroma * vec2(1.0, 1.0 / aspect);
    float vign = 1.0 - smoothstep(0.72, 1.12, length((tc - m) * ar));
    vign = mix(0.88, 1.18, vign);
    vec3 rC = preBlendColor(u0 + off, seed + 0.1, drive);
    vec3 gC = preBlendColor(u1, seed + 0.2, drive);
    vec3 bC = preBlendColor(u2 - off, seed + 0.3, drive);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);
    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * (9.5 + 2.0 * drive) + seed * 1.2));
    float pulse = 0.5 + 0.5 * sin(seed * 2.0 + rD * 28.0 + k * 12.0 + drive * 8.0);
    float shutter = smoothstep(0.0, 1.0, sin(PI * clamp(dt * fr * 0.5, 0.0, 1.0)));
    vec2 shake = (hash21(vec2(seed, rD)) * 2.0 - 1.0) * 0.0015 * shutter * vec2(1.0, 1.0 / aspect);
    vec3 outCol = kaleidoRGB;
    outCol *= (0.70 + 0.30 * ring) * (0.85 + 0.15 * pulse) * vign;
    vec3 bloom = outCol * outCol * (0.14 + 0.10 * drive) + pow(max(outCol - 0.6, 0.0), vec3(2.0)) * (0.10 + 0.08 * drive);
    outCol += bloom;
    outCol = mix(outCol, baseCol, 0.16);
    float dayGate = step(0.5, fract(daySeed * 0.001 + sin(iDate.w + seed) * 0.5 + 0.5));
    outCol = mix(outCol, hsv2rgb(vec3(fract(seed * 0.07 + rD * 0.15), 0.9, 1.0)), 0.10 * dayGate);
    outCol = clamp(outCol, vec3(0.04), vec3(1.2));
    vec3 src0 = texture(samp, tc + shake).rgb;
    vec3 srcR = texture(samp, tc + off + shake).rgb;
    vec3 srcB = texture(samp, tc - off + shake).rgb;
    vec3 srcCA = vec3(srcR.r, src0.g, srcB.b);
    float mixBase = pingPong(glow * PI, 5.0) * (0.75 + 0.25 * drive);
    float focus = smoothstep(0.0, 1.0, 1.0 - length((tc - m) * ar) * 1.1);
    vec3 combined = mix(srcCA, outCol, clamp(mixBase * focus, 0.0, 1.0));
    combined = aces(combined);
    color = vec4(combined, baseTex.a);
}
