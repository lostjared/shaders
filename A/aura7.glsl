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
    vec3 pink = vec3(1.00, 0.20, 0.80);
    vec3 blue = vec3(0.10, 0.65, 1.00);
    vec3 green = vec3(0.15, 1.00, 0.55);
    float ph = fract(t * 0.12);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3);
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

vec3 sharpen3(sampler2D img, vec2 uv, vec2 res) {
    vec3 blur = tentBlur3(img, uv, res);
    vec3 base = texture(img, uv).rgb;
    return clamp(base * 1.6 - blur * 0.6, 0.0, 1.0);
}

vec3 preBlendColor(vec2 uv, float seed, float drive) {
    vec3 tex = sharpen3(samp, uv, iResolution);
    vec3 neon = neonPalette(seed + drive * 0.2);
    vec3 grad = mix(tex, mix(tex, neon, 0.75), 0.45);
    float l = dot(grad, vec3(0.299, 0.587, 0.114));
    float satAmt = 1.25 + drive * 0.35;
    grad = mix(vec3(l), grad, satAmt);
    return clamp(grad, 0.0, 1.0);
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

vec3 contrastCurve(vec3 c, float k) {
    c = clamp(c, 0.0, 1.0);
    return clamp((c - 0.5) * (1.0 + k) + 0.5, 0.0, 1.0);
}

void main(void) {
    vec4 baseTex = texture(samp, tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);

    vec2 mouseN = iMouse.xy / iResolution;
    vec2 clickN = iMouseClick / iResolution;
    bool hasClick = max(iMouseClick.x, iMouseClick.y) > 0.0;

    vec2 mCore = (iMouse.z > 0.5) ? mouseN : (hasClick ? clickN : vec2(0.5));

    float t = time_f + iTime * 0.75 + float(iFrame) * 0.0005;
    float daySeed = iDate.x * 37.0 + iDate.y * 17.0 + iDate.z * 7.0 + iDate.w;
    float seed = t + daySeed * 0.013 + float(iFrame) * 0.001;
    float fr = max(iFrameRate, 1.0);
    float dt = max(iTimeDelta, 1.0 / fr);
    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);
    float drive = clamp(aMix * 0.10, 0.0, 3.0);

    vec2 uvCenter = (tc - mCore) * 2.0;
    uvCenter.x *= aspect;
    float beat = 0.5 + 0.5 * sin(t * 3.1 + drive * 5.0);
    float ringR = mix(0.85, 1.35, beat * (0.85 + 0.15 * sr));
    float r = length(uvCenter);
    float glow = smoothstep(ringR, ringR - 0.22, r);

    float seg = clamp(4.0 + 3.0 * sin(seed * 0.33 + 0.1 * sr), 3.0, 12.0);
    float zoom = 1.55 + 0.65 * sin(seed * (0.42 + 0.10 * sr));
    vec3 baseCol = preBlendColor(tc, seed, drive);

    vec2 kUV = reflectUV(tc, seg, mCore, aspect);
    kUV = diamondFold(kUV, mCore, aspect);
    kUV = fractalFold(kUV, zoom, seed, mCore, aspect);
    kUV = rotateUV(kUV, seed * (0.26 + 0.10 * drive), mCore, aspect);
    kUV = diamondFold(kUV, mCore, aspect);

    vec2 p = (kUV - mCore) * ar;
    vec2 q = abs(p);
    if (q.y > q.x)
        q = q.yx;
    float base = 1.82 + 0.18 * sin(seed * 0.2);
    float period = log(base);
    float tz = seed * 0.65;
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + seed * 0.6 + drive * 3.0);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + mCore);
    vec2 u1 = fract((pwrap * (1.03 + 0.02 * drive)) / ar + mCore);
    vec2 u2 = fract((pwrap * (0.97 - 0.02 * drive)) / ar + mCore);

    vec2 dir = normalize(pwrap + 1e-6);
    float chroma = (0.0016 + 0.0012 * drive) * (1.0 + 0.25 * sin(seed * 1.4));
    vec2 off = dir * chroma * vec2(1.0, 1.0 / aspect);

    float vign = 1.0 - smoothstep(0.78, 1.18, length((tc - mCore) * ar));
    vign = mix(0.92, 1.22, vign);

    vec3 rC = preBlendColor(u0 + off, seed + 0.1, drive);
    vec3 gC = preBlendColor(u1, seed + 0.2, drive);
    vec3 bC = preBlendColor(u2 - off, seed + 0.3, drive);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * (9.5 + 2.0 * drive) + seed * 1.2));
    float pulse = 0.5 + 0.5 * sin(seed * 2.2 + rD * 28.0 + k * 12.0 + drive * 8.0);

    vec3 outCol = kaleidoRGB;
    outCol *= (0.72 + 0.28 * ring) * (0.85 + 0.15 * pulse) * vign;

    vec3 bloom = outCol * outCol * (0.18 + 0.10 * drive) + pow(max(outCol - 0.55, 0.0), vec3(2.0)) * (0.14 + 0.10 * drive);
    outCol += bloom;

    float exposure = 1.25 + 0.35 * drive;
    outCol *= exposure;
    outCol = contrastCurve(outCol, 0.45 + 0.25 * drive);
    float l = dot(outCol, vec3(0.299, 0.587, 0.114));
    outCol = mix(vec3(l), outCol, 1.35 + 0.25 * drive);
    outCol = clamp(outCol, 0.0, 3.0);
    outCol = aces(outCol);

    color = vec4(mix(baseTex.rgb, outCol, 0.85), baseTex.a);
}
