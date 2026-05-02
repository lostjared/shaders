#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float seed;

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

vec3 preBlendColor(vec2 uv, float tSlow, float tFast, float aspect) {
    vec3 tex = tentBlur3(samp, uv, iResolution);
    vec2 gdir = normalize(vec2(cos(tSlow * 0.27), sin(tSlow * 0.31)));
    float s = dot((uv - 0.5) * vec2(aspect, 1.0), gdir);
    float w = max(fwidth(s) * 4.0, 0.002);
    float band = smoothstep(-0.5 - w, -0.5 + w, sin(s * 2.2 + tFast * 0.9));
    vec3 neon = neonPalette(tFast);
    vec3 grad = mix(tex, mix(tex, neon, 0.6), 0.35 + 0.25 * band);
    grad = mix(grad, tex, 0.10);
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

vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

vec2 h2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                          dot(p, vec2(269.5, 183.3)))) *
                 43758.5453);
}

vec3 limitHighlights(vec3 c) {
    float m = max(c.r, max(c.g, c.b));
    if (m > 0.9)
        c *= 0.9 / m;
    return c;
}

void main(void) {
    float a = clamp(amp, 0.0, 1.0);
    float ua = clamp(uamp, 0.0, 1.0);
    float aMix = clamp(amp * 0.7 + uamp * 1.3, 0.0, 4.0);
    float a01 = clamp(aMix / 2.5, 0.0, 1.0);

    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);

    float tBase = time_f;
    float tSlow = tBase * mix(0.2, 0.9, a01);
    float tFast = tBase * mix(0.7, 3.5, a01);

    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution)
                              : fract(vec2(0.37 + 0.11 * sin(tSlow * 0.63 + seed),
                                           0.42 + 0.13 * cos(tSlow * 0.57 + seed * 2.0)));

    vec2 tc0 = tc;
    vec2 center = vec2(0.5, 0.5);
    float radius = length(tc0 - center);

    float rippleSpeed = 5.0 * (1.0 + 2.0 * a01);
    float rippleAmplitude = 0.03 * (0.5 + 1.5 * a01);
    float rippleWavelength = 10.0;
    float twistStrength = 1.0 + 4.0 * a01;

    float ripple = sin(tc0.x * rippleWavelength + tFast * rippleSpeed) * rippleAmplitude;
    ripple += sin(tc0.y * rippleWavelength + tFast * rippleSpeed) * rippleAmplitude;
    vec2 rippleTC = tc0 + vec2(ripple, ripple);

    float angleTwist = twistStrength * (radius - 1.0) + tSlow;
    float cosA = cos(angleTwist);
    float sinA = sin(angleTwist);
    mat2 rotationMatrix = mat2(cosA, -sinA, sinA, cosA);
    vec2 twistedTC = rotationMatrix * (tc0 - center) + center;

    float mixRT = 0.5 + 0.35 * a01;
    vec2 tcRT = mix(rippleTC, twistedTC, mixRT);

    vec4 baseTex = texture(samp, tcRT);

    vec2 uvForGlow = tcRT * 2.0 - 1.0;
    uvForGlow.x *= aspect;
    float rGlow = pingPong(sin(length(uvForGlow) * tSlow), 5.0);
    float radiusMax = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radiusMax, radiusMax - 0.25, rGlow);

    vec2 uv = tcRT;
    float speedScale = 1.0 + 2.0 * a01 + 3.0 * ua;

    float speedR = 5.0 * speedScale;
    float speedG = 6.5 * speedScale;
    float speedB = 4.0 * speedScale;
    float ampR = 0.03 * (0.7 + 0.6 * a01);
    float ampG = 0.025 * (0.7 + 0.6 * a01);
    float ampB = 0.035 * (0.7 + 0.6 * a01);
    float waveR = 10.0;
    float waveG = 12.0;
    float waveB = 8.0;

    float rR = sin(uv.x * waveR + tFast * speedR) * ampR + sin(uv.y * waveR * 0.8 + tFast * speedR * 1.2) * ampR;
    float rG = sin(uv.x * waveG * 1.5 + tFast * speedG) * ampG + sin(uv.y * waveG * 0.3 + tFast * speedG * 0.7) * ampG;
    float rB = sin(uv.x * waveB * 0.5 + tFast * speedB) * ampB + sin(uv.y * waveB * 1.7 + tFast * speedB * 1.3) * ampB;

    vec2 tcR = uv + vec2(rR, rR);
    vec2 tcG = uv + vec2(rG, -0.5 * rG);
    vec2 tcB = uv + vec2(0.3 * rB, rB);

    vec3 pats[4] = vec3[](vec3(1, 0, 1), vec3(0, 1, 0), vec3(1, 0, 0), vec3(0, 0, 1));
    float pspd = 4.0;
    int pidx = int(mod(floor(tBase * pspd + seed * 4.0), 4.0));
    vec3 mir = pats[pidx];

    vec2 dR = tcR - m;
    vec2 dG = tcG - m;
    vec2 dB = tcB - m;

    float fallR = smoothstep(0.55, 0.0, length(dR));
    float fallG = smoothstep(0.55, 0.0, length(dG));
    float fallB = smoothstep(0.55, 0.0, length(dB));

    float sw = (0.12 + 0.38 * ua + 0.25 * a);
    vec2 tangR = rot2(normalize(dR + 1e-4), 1.5707963);
    vec2 tangG = rot2(normalize(dG + 1e-4), 1.5707963);
    vec2 tangB = rot2(normalize(dB + 1e-4), 1.5707963);

    vec2 airR = tangR * sw * fallR * (0.06 + 0.22 * a) * (0.6 + 0.4 * cos(uv.y * 40.0 + tFast * 3.0 + seed));
    vec2 airG = tangG * sw * fallG * (0.06 + 0.22 * a) * (0.6 + 0.4 * cos(uv.y * 38.0 + tFast * 3.3 + seed * 1.7));
    vec2 airB = tangB * sw * fallB * (0.06 + 0.22 * a) * (0.6 + 0.4 * cos(uv.y * 42.0 + tFast * 2.9 + seed * 0.9));

    vec2 jit = (h2(uv * vec2(233.3, 341.9) + tFast + seed) - 0.5) * (0.0006 + 0.004 * ua);

    tcR += airR + jit;
    tcG += airG + jit;
    tcB += airB + jit;

    vec2 fR = vec2(mir.r > 0.5 ? 1.0 - tcR.x : tcR.x, tcR.y);
    vec2 fG = vec2(mir.g > 0.5 ? 1.0 - tcG.x : tcG.x, tcG.y);
    vec2 fB = vec2(mir.b > 0.5 ? 1.0 - tcB.x : tcB.x, tcB.y);

    float seg = 4.0 + 2.0 * sin(tSlow * 0.33 + a01 * 2.0);
    vec2 kUV = reflectUV(tcRT, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.45 + 0.55 * sin(tSlow * 0.42 + a01 * 3.0);
    kUV = fractalFold(kUV, foldZoom, tFast, m, aspect);
    kUV = rotateUV(kUV, tSlow * 0.23 + a01 * 1.1, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x)
        q = q.yx;

    float base = 1.82 + 0.18 * pingPong(sin(tSlow * 0.2) * (PI * tSlow), 5.0);
    float period = log(base) * pingPong(tSlow * PI, 5.0);
    float tz = tSlow * 0.65;
    float rD = diamondRadius(p) + 1e-6;

    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + tFast * 0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);

    vec2 dirK = normalize(pwrap + 1e-6);
    vec2 off = dirK * (0.0015 + 0.001 * sin(tFast * 1.3)) * vec2(1.0, 1.0 / aspect);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((tcRT - m) * ar));
    vign = mix(0.9, 1.15, vign);

    vec2 sR = mix(u0, fR, 0.6);
    vec2 sG = mix(u1, fG, 0.6);
    vec2 sB = mix(u2, fB, 0.6);

    vec3 rC = preBlendColor(sR + off, tSlow, tFast, aspect);
    vec3 gC = preBlendColor(sG, tSlow, tFast, aspect);
    vec3 bC = preBlendColor(sB - off, tSlow, tFast, aspect);

    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + tFast * 1.2));
    ring = ring * pingPong(tSlow * PI, 5.0);
    float pulse = 0.5 + 0.5 * sin(tFast * 2.0 + rD * 28.0 + k * 12.0);
    pulse *= mix(0.4, 1.4, a01);

    vec3 outCol = kaleidoRGB;
    outCol *= (0.75 + 0.25 * ring) * (0.85 + 0.15 * pulse) * vign;

    vec3 bloom = outCol * outCol * 0.10 + pow(max(outCol - 0.6, 0.0), vec3(2.0)) * 0.06;

    float pulseAdd = 0.004 * (0.5 + 0.5 * sin(tFast * 3.7 + seed));
    outCol += bloom;
    outCol += pulseAdd * ua;

    outCol = clamp(outCol, vec3(0.0), vec3(1.0));
    outCol = limitHighlights(outCol);

    vec3 finalRGB = mix(baseTex.rgb, outCol, pingPong(glow * PI, 5.0) * (0.6 + 0.3 * a01));
    finalRGB = limitHighlights(finalRGB);
    finalRGB = clamp(finalRGB, 0.0, 1.0);

    color = vec4(finalRGB, baseTex.a);
}
