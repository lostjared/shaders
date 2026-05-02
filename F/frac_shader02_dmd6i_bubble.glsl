#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

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

vec3 preBlendColor(vec2 uv) {
    vec3 tex = tentBlur3(samp, uv, iResolution);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float t = time_f;
    vec3 neon = neonPalette(t + r * 1.3);
    float neonAmt = smoothstep(0.1, 0.8, r);
    neonAmt = 0.3 + 0.4 * (1.0 - neonAmt);
    vec3 grad = mix(tex, neon, neonAmt);
    grad = mix(grad, tex, 0.2);
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

void main(void) {
    float audio = clamp(amp * 0.8 + uamp * 0.6, 0.0, 5.0);
    float audioNorm = clamp(audio * 0.5, 0.0, 2.5);
    float t = time_f * (1.0 + audioNorm * 0.25);

    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec2 rel = tc - m;
    float dist = length(rel);
    float bubSize = 0.38 + 0.12 * audioNorm;
    float bubEdge = 0.28 + 0.10 * audioNorm;
    float bubMask = 1.0 - smoothstep(bubSize, bubSize + bubEdge, dist);

    float zoomBase = 1.3 + 0.7 * audioNorm;
    float zoomAnim = 0.5 + 0.5 * sin(t * 1.6 + audioNorm * 2.3);
    float zoom = mix(1.0, zoomBase, zoomAnim);

    vec2 tcZoom = m + rel / zoom;
    vec2 tcF = mix(tc, tcZoom, bubMask);

    vec4 baseTex = texture(samp, tcF);

    vec2 uv = tcF * 2.0 - 1.0;
    uv.x *= aspect;
    float r = pingPong(sin(length(uv) * t), 5.0);
    float radius = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radius, radius - 0.25, r);

    vec3 baseCol = preBlendColor(tcF);

    float seg = 4.0 + 2.0 * sin(t * 0.33);
    vec2 kUV = reflectUV(tcF, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    float foldZoom = 1.45 + 0.55 * sin(t * 0.42);
    kUV = fractalFold(kUV, foldZoom, t, m, aspect);
    kUV = rotateUV(kUV, t * 0.23, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x)
        q = q.yx;

    float base = 1.82 + 0.18 * pingPong(sin(t * 0.2) * (PI * t), 5.0);
    float period = log(base) * pingPong(t * PI, 5.0);
    float tz = t * 0.65;

    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + t * 0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);

    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);

    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(t * 1.3)) * vec2(1.0, 1.0 / aspect);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((tcF - m) * ar));
    vign = mix(0.9, 1.15, vign);

    vec3 rC = preBlendColor(u0 + off);
    vec3 gC = preBlendColor(u1);
    vec3 bC = preBlendColor(u2 - off);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    float angDir = atan(p.y, p.x) / (2.0 * PI);
    angDir = angDir * 0.5 + 0.5;
    float radN = clamp(length(p) * 0.9, 0.0, 1.0);

    float hueShift = pingPong(time_f * 0.18 + audioNorm * 0.12, 1.0);
    float hue = fract(angDir + (radN - 0.5) * 0.4 + (hueShift - 0.5) * 0.6);
    float sat = 0.4 + 0.4 * radN;
    float val = 0.45 + 0.45 * (1.0 - radN);

    vec3 gradCol = hsv2rgb(vec3(hue, sat, val));

    float gMix = (0.18 + 0.25 * audioNorm) * (0.3 + 0.7 * bubMask);
    vec3 outCol = mix(kaleidoRGB, kaleidoRGB * gradCol, gMix);

    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + t * 1.2));
    ring = ring * pingPong((t * PI), 5.0);
    float pulse = 0.5 + 0.5 * sin(t * 2.0 + rD * 28.0 + k * 12.0 + audioNorm * 3.0);

    outCol *= (0.60 + 0.20 * ring) * (0.80 + 0.10 * pulse) * vign;

    vec3 bloom = outCol * outCol * 0.08;
    outCol += bloom * 0.3;

    outCol = mix(outCol, baseTex.rgb, 0.18 + audioNorm * 0.04);

    float rim = smoothstep(bubSize + 0.02, bubSize - 0.02, dist);
    vec3 bubbleHighlight = hsv2rgb(vec3(hue, 0.7, 0.9)) * rim * (0.10 + 0.20 * audioNorm);
    outCol += bubbleHighlight * bubMask * 0.5;

    outCol = clamp(outCol, vec3(0.05), vec3(0.90));

    vec3 finalRGB = mix(baseTex.rgb, outCol, pingPong(glow * PI, 5.0) * 0.7 + 0.1);

    float maxC = max(max(finalRGB.r, finalRGB.g), finalRGB.b);
    float targetMax = 0.97;
    if (maxC > targetMax)
        finalRGB *= targetMax / maxC;
    finalRGB = clamp(finalRGB, vec3(0.03), vec3(0.97));

    color = vec4(finalRGB, baseTex.a);
}
