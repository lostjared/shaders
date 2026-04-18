#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform float time_speed;
uniform sampler2D samp;
uniform vec2 iResolution;
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
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float PI  = 3.1415926535897932384626433832795;
const float TAU = 6.28318530718;

// --- utility ---

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

vec2 rotateUV(vec2 uv, float angle, vec2 ctr, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - ctr;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + ctr;
}

vec2 reflectUV(vec2 uv, float segments, vec2 ctr, float aspect) {
    vec2 p = uv - ctr;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float step_ = TAU / segments;
    ang = mod(ang, step_);
    ang = abs(ang - step_ * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + ctr;
}

float diamondRadius(vec2 p) {
    p = abs(p);
    return max(p.x, p.y);
}

vec2 diamondFold(vec2 uv, vec2 ctr, float aspect) {
    vec2 p = (uv - ctr) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + ctr;
}

// --- recursive fractal fold (depth scales with audio) ---
vec2 fractalFold(vec2 uv, float zoom, float t, vec2 ctr, float aspect, int iters, float aLow) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        p = abs((p - ctr) * (zoom + 0.15 * sin(t * (0.35 + aLow * 0.2) + float(i)))) - 0.5 + ctr;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, ctr, aspect);
    }
    return p;
}

// --- secondary recursive warp (nested sine fold) ---
vec2 sineFold(vec2 uv, float t, float strength, int iters) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        float fi = float(i);
        p.x += strength * sin(p.y * (6.0 + fi * 2.3) + t * (0.9 + fi * 0.4));
        p.y += strength * cos(p.x * (5.0 + fi * 1.7) + t * (1.1 + fi * 0.3));
        p = fract(p);
    }
    return p;
}

// --- neon palette ---
vec3 neonPalette(float t) {
    vec3 pink  = vec3(1.0, 0.15, 0.75);
    vec3 blue  = vec3(0.10, 0.55, 1.0);
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
    vec3 s  = vec3(0.0);
    s += 1.0 * textureGrad(img, uv + ts * vec2(-1,-1), dFdx(uv), dFdy(uv)).rgb;
    s += 2.0 * textureGrad(img, uv + ts * vec2( 0,-1), dFdx(uv), dFdy(uv)).rgb;
    s += 1.0 * textureGrad(img, uv + ts * vec2( 1,-1), dFdx(uv), dFdy(uv)).rgb;
    s += 2.0 * textureGrad(img, uv + ts * vec2(-1, 0), dFdx(uv), dFdy(uv)).rgb;
    s += 4.0 * textureGrad(img, uv,                     dFdx(uv), dFdy(uv)).rgb;
    s += 2.0 * textureGrad(img, uv + ts * vec2( 1, 0), dFdx(uv), dFdy(uv)).rgb;
    s += 1.0 * textureGrad(img, uv + ts * vec2(-1, 1), dFdx(uv), dFdy(uv)).rgb;
    s += 2.0 * textureGrad(img, uv + ts * vec2( 0, 1), dFdx(uv), dFdy(uv)).rgb;
    s += 1.0 * textureGrad(img, uv + ts * vec2( 1, 1), dFdx(uv), dFdy(uv)).rgb;
    return s / 16.0;
}

vec3 limitHighlights(vec3 c) {
    float m = max(c.r, max(c.g, c.b));
    if (m > 0.9) c *= 0.9 / m;
    return c;
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2  ar     = vec2(aspect, 1.0);

    // --- audio mix: 0 when silent, ramps up with input ---
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 10.0);
    float a01  = clamp(aMix / 2.5, 0.0, 1.0);
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);

    float t = time_f;
    float tSlow = t * mix(0.3, 1.0, a01);
    float tFast = t * mix(0.8, 3.0, a01);

    vec2 ctr = (iMouse.z > 0.5)
             ? iMouse.xy / iResolution
             : vec2(0.5 + 0.08 * sin(tSlow * 0.47), 0.5 + 0.08 * cos(tSlow * 0.39));

    // --- layer 1: kaleidoscope + fractal fold ---
    float seg  = 6.0 + 2.0 * sin(tSlow * 0.25) + 2.0 * a01;
    float zoom = 1.4 + 0.5 * sin(tSlow * 0.35) + 0.3 * aLow;
    int foldIters = 6 + int(a01 * 4.0);  // 6 base, up to 10 with audio

    vec2 kUV = reflectUV(tc, seg, ctr, aspect);
    kUV = diamondFold(kUV, ctr, aspect);
    kUV = fractalFold(kUV, zoom, tFast, ctr, aspect, foldIters, aLow);
    kUV = rotateUV(kUV, tSlow * 0.2, ctr, aspect);
    kUV = diamondFold(kUV, ctr, aspect);

    // --- layer 2: secondary sine-fold recursion ---
    float sinStr  = 0.02 + 0.04 * a01;
    int   sinIter = 4 + int(a01 * 4.0);  // 4 base, up to 8 with audio
    vec2  sFold   = sineFold(kUV, tFast * 0.6, sinStr, sinIter);

    // blend the two recursive layers
    float layerMix = 0.5 + 0.3 * sin(tSlow * 0.5) + 0.2 * aMid;
    vec2 warpUV = mix(kUV, sFold, layerMix);

    // --- layer 3: log-polar spiral warp ---
    vec2  p  = (warpUV - ctr) * ar;
    float rD = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    float spiralTwist = 0.4 + 1.2 * a01;
    ang += spiralTwist * sin(rD * 12.0 + tFast * 0.7);

    float base_  = 1.8 + 0.2 * pingPong(sin(tSlow * 0.2) * PI * tSlow, 5.0);
    float period = log(base_) * pingPong(tSlow * PI, 5.0);
    float k      = fract((log(rD) - tSlow * 0.6) / max(period, 0.01));
    float rw     = exp(k * max(period, 0.01));
    vec2  pwrap  = vec2(cos(ang), sin(ang)) * rw;
    vec2  logUV  = fract(pwrap / ar + ctr);

    // --- chromatic split driven by recursion depth ---
    float chromaStr = 0.003 + 0.008 * a01 + 0.005 * aPk;
    vec2  chromaDir = normalize(pwrap + 1e-5) * chromaStr * vec2(1.0, 1.0 / aspect);

    vec2 uvR = logUV + chromaDir;
    vec2 uvG = logUV;
    vec2 uvB = logUV - chromaDir;

    // --- layer 4: per-channel recursive ripple ---
    float ripAmp = 0.01 + 0.02 * a01;
    uvR += ripAmp * vec2(sin(uvR.y * 30.0 + tFast * 4.0), cos(uvR.x * 28.0 + tFast * 3.5));
    uvG += ripAmp * vec2(sin(uvG.y * 32.0 + tFast * 3.7), cos(uvG.x * 26.0 + tFast * 4.2));
    uvB += ripAmp * vec2(sin(uvB.y * 28.0 + tFast * 4.3), cos(uvB.x * 30.0 + tFast * 3.2));

    // sample texture per channel
    vec3 rC = tentBlur3(samp, fract(uvR), iResolution);
    vec3 gC = tentBlur3(samp, fract(uvG), iResolution);
    vec3 bC = tentBlur3(samp, fract(uvB), iResolution);
    vec3 fracCol = vec3(rC.r, gC.g, bC.b);

    // --- neon color overlay ---
    vec3 neon    = neonPalette(tSlow + rD * 1.5);
    float neonAmt = 0.25 + 0.15 * aMid;
    fracCol = mix(fracCol, neon * fracCol * 2.0, neonAmt);
    fracCol = softTone(fracCol);

    // --- ring/pulse patterns ---
    float ring  = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + tFast * 1.2));
    ring *= pingPong(tSlow * PI, 5.0);
    float pulse = 0.5 + 0.5 * sin(tFast * 2.0 + rD * 28.0 + k * 12.0);
    pulse *= mix(0.4, 1.4, a01);

    fracCol *= (0.8 + 0.2 * ring) * (0.88 + 0.12 * pulse);

    // --- vignette ---
    float vign = 1.0 - smoothstep(0.6, 1.3, length((tc - ctr) * ar));
    vign = mix(0.85, 1.15 + amp_smooth * 0.2, vign);
    fracCol *= vign;

    // --- bloom ---
    vec3 bloom = fracCol * fracCol * 0.14
               + pow(max(fracCol - 0.6, 0.0), vec3(2.0)) * 0.08;
    fracCol += bloom;

    // --- blend with original texture ---
    vec3 baseTex = textureGrad(samp, tc, dFdx(tc), dFdy(tc)).rgb;
    float blendAmt = 0.65 + 0.2 * a01;
    vec3 outCol = mix(baseTex, fracCol, blendAmt);

    outCol = clamp(outCol, 0.0, 1.0);
    outCol = limitHighlights(outCol);

    // --- audio reactivity: direct output modulation ---
    outCol *= 1.0 + aPk * 0.6;
    outCol = mix(outCol,
                 outCol * vec3(1.0 + aLow * 0.3,
                               1.0 - aLow * 0.15,
                               1.0 + aHigh * 0.25),
                 aPk);

    color = vec4(outCol, 1.0);
}

