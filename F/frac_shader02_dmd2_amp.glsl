#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
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

vec3 preBlendColor(vec2 uv, float t) {
    float aspect = iResolution.x / iResolution.y;
    vec3 tex = tentBlur3(samp, uv, iResolution);
    vec2 gdir = normalize(vec2(cos(t * 0.27), sin(t * 0.31)));
    float s = dot((uv - 0.5) * vec2(aspect, 1.0), gdir);
    float w = max(fwidth(s) * 4.0, 0.002);
    float band = smoothstep(-0.5 - w, -0.5 + w, sin(s * 2.2 + t * 0.9));
    vec3 neon = neonPalette(t);
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
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + c;
}

vec3 limitHighlights(vec3 c) {
    float m = max(c.r, max(c.g, c.b));
    if (m > 0.95) c *= 0.95 / m;
    return c;
}

void main(void) {
    float aAcc = clamp(amp, 0.0, 20.0);
    float aInst = clamp(uamp, 0.0, 20.0);
    float aMix = clamp(aAcc * 0.5 + aInst * 1.0, 0.0, 20.0);
    float a01 = clamp(aMix / 6.0, 0.0, 1.0);

    float aspect = iResolution.x / iResolution.y;
    vec2 center = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5, 0.5);

    float tSpin  = time_f * mix(0.3, 1.8, a01);
    float tSlow  = time_f * mix(0.2, 0.9, a01);
    float tFast  = time_f * mix(0.8, 3.2, a01);

    vec2 offset = tc - center;
    float maxRadius = length(vec2(0.5, 0.5));
    float radius = length(offset);
    float normalizedRadius = radius / maxRadius;
    float angle = atan(offset.y, offset.x);

    float distortion = 0.25 + 0.75 * a01;
    float distortedRadius = normalizedRadius + distortion * normalizedRadius * normalizedRadius;
    distortedRadius = clamp(distortedRadius, 0.0, 1.0);
    distortedRadius *= maxRadius;

    vec2 distortedCoords = center + distortedRadius * vec2(cos(angle), sin(angle));

    float modulatedTime = pingPong(tSpin, 5.0);
    angle += modulatedTime;

    vec2 rotatedTC;
    rotatedTC.x = cos(angle) * (distortedCoords.x - center.x)
                - sin(angle) * (distortedCoords.y - center.y) + center.x;
    rotatedTC.y = sin(angle) * (distortedCoords.x - center.x)
                + cos(angle) * (distortedCoords.y - center.y) + center.y;

    float warpSpeed = 0.05 + 0.25 * a01 + 0.2 * (aInst / (aInst + 1.0));
    vec2 warpedCoords;
    warpedCoords.x = pingPong(rotatedTC.x + tSpin * warpSpeed, 1.0);
    warpedCoords.y = pingPong(rotatedTC.y + tSpin * warpSpeed, 1.0);

    vec2 uvGlow = warpedCoords * 2.0 - 1.0;
    uvGlow.x *= aspect;
    float rGlow = length(uvGlow);
    float radiusMax = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radiusMax, radiusMax - 0.25, rGlow);

    vec2 m = center;
    vec2 ar = vec2(aspect, 1.0);

    vec3 baseColBlur = preBlendColor(warpedCoords, tSlow);
    float seg = 4.0 + 2.0 * sin(tSlow * 0.33 + a01 * 2.0);

    vec2 kUV = reflectUV(warpedCoords, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    float foldZoom = 1.45 + 0.55 * sin(tSlow * 0.42 + a01 * 3.0);
    kUV = fractalFold(kUV, foldZoom, tFast, m, aspect);
    kUV = rotateUV(kUV, tSlow * 0.23 + a01 * 1.1, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x) q = q.yx;

    float base = 1.82 + 0.18 * sin(tSlow * 0.2);
    float period = log(base);
    float tz = tSlow * 0.65;
    float rD = diamondRadius(p) + 1e-6;

    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + tFast * 0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);

    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(tFast * 1.3)) * vec2(1.0, 1.0 / aspect);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((warpedCoords - m) * ar));
    vign = mix(0.9, 1.15, vign);

    vec3 rC = preBlendColor(u0 + off, tFast);
    vec3 gC = preBlendColor(u1,       tFast);
    vec3 bC = preBlendColor(u2 - off, tFast);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + tFast * 1.2));
    float pulse = 0.5 + 0.5 * sin(tFast * 2.0 + rD * 28.0 + k * 12.0);
    pulse *= mix(0.4, 1.4, a01);

    vec3 outCol = kaleidoRGB;
    outCol *= (0.75 + 0.25 * ring) * (0.85 + 0.15 * pulse) * vign;

    vec3 bloom = outCol * outCol * 0.10
               + pow(max(outCol - 0.6, 0.0), vec3(2.0)) * 0.06;
    outCol += bloom;

    outCol = mix(outCol, baseColBlur, 0.18 + 0.3 * a01);
    outCol = limitHighlights(outCol);
    outCol = clamp(outCol, 0.0, 1.0);

    vec4 baseTex = texture(samp, warpedCoords);
    float mixAmt = pingPong(glow * PI, 5.0) * mix(0.4, 0.9, a01);
    vec3 finalRGB = mix(baseTex.rgb, outCol, mixAmt);
    finalRGB = limitHighlights(finalRGB);
    finalRGB = clamp(finalRGB, 0.0, 1.0);

    color = vec4(finalRGB, baseTex.a);
}
