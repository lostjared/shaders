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

float gAmp01;
float gSlow;
float gFast;
float gDetail;

vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255.0);
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255.0 * icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if (int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255.0;
    }
    icolor.a = 1.0;
    return icolor;
}

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
    float aAcc = clamp(amp, 0.0, 4.0);
    float aInst = clamp(uamp, 0.0, 4.0);
    float ampMix = clamp(aAcc * 0.6 + aInst * 1.4, 0.0, 4.0);
    gAmp01 = clamp(ampMix / 2.5, 0.0, 1.0);

    gSlow = time_f * mix(0.15, 0.7, gAmp01);
    gFast = time_f * mix(0.6, 3.5, gAmp01);
    gDetail = time_f * mix(0.3, 2.0, gAmp01);

    float aspect = iResolution.x / iResolution.y;
    vec2 m = (iMouse.z > 0.5 || iMouse.w > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 ar = vec2(aspect, 1.0);

    float zoomPhase = gSlow * 0.12;
    float zCycle = floor(zoomPhase);
    float zLocal = fract(zoomPhase);
    float tri = 1.0 - abs(zLocal * 2.0 - 1.0);
    float sgn = mix(-1.0, 1.0, step(0.5, mod(zCycle, 2.0)));
    float depth = 1.0 + zCycle * 0.35 + gAmp01 * 1.2;
    float zoomExp = sgn * tri * depth;
    float zoom = pow(1.45, zoomExp);

    vec2 z = tc - m;
    z.x *= aspect;
    z /= zoom;
    z.x /= aspect;
    vec2 zoomTC = fract(z + m);

    vec4 baseTex = texture(samp, zoomTC);

    vec2 uv = zoomTC * 2.0 - 1.0;
    uv.x *= aspect;
    float r = pingPong(sin(length(uv) * gSlow), 5.0);
    float radius = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radius, radius - 0.25, r);

    vec3 baseCol = preBlendColor(zoomTC);
    float seg = 4.0 + 2.0 * sin(gSlow * 0.33 + gAmp01 * 2.0);
    vec2 kUV = reflectUV(zoomTC, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.45 + 0.55 * sin(gSlow * 0.42 + gAmp01 * 3.0);
    kUV = fractalFold(kUV, foldZoom, gDetail, m, aspect);
    kUV = rotateUV(kUV, gSlow * 0.23 + gAmp01 * 1.2, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x)
        q = q.yx;

    float base = 1.82 + 0.18 * pingPong(sin(gSlow * 0.2) * (PI * gSlow), 5.0);
    float period = log(base) * pingPong(gSlow * PI, 5.0);
    float tz = gSlow * 0.65;
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + gFast * 0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);
    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(gFast * 1.3)) * vec2(1.0, 1.0 / aspect);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((zoomTC - m) * ar));
    vign = mix(0.9, 1.15, vign);

    vec3 rC = preBlendColor(u0 + off);
    vec3 gC = preBlendColor(u1);
    vec3 bC = preBlendColor(u2 - off);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + gFast * 1.2));
    ring = ring * pingPong(gSlow * PI, 5.0);
    float pulse = 0.5 + 0.5 * sin(gFast * 2.0 + rD * 28.0 + k * 12.0);
    pulse *= mix(0.4, 1.6, gAmp01);

    vec3 outCol = kaleidoRGB;
    outCol *= (0.75 + 0.25 * ring) * (0.85 + 0.15 * pulse) * vign;

    vec3 bloom = outCol * outCol * 0.18 + pow(max(outCol - 0.6, 0.0), vec3(2.0)) * 0.12;
    outCol += bloom;

    outCol = mix(outCol, baseCol, pingPong(pulse * PI, 5.0) * 0.18);
    outCol = clamp(outCol, vec3(0.05), vec3(0.97));
    outCol *= mix(0.7, 1.5, gAmp01);
    vec3 finalCore = mix(baseTex.rgb, outCol, pingPong(glow * PI, 5.0) * 0.8);

    vec2 center = m;
    vec2 pSwirl = (zoomTC - center) * vec2(1.0, iResolution.y / iResolution.x);
    float intensity = pingPong(gSlow, 10.0) * (0.3 + 1.7 * gAmp01);
    float angleS = atan(pSwirl.y, pSwirl.x);
    float radiusS = length(pSwirl);
    float swirl = sin(gSlow * 0.5) * 0.5 + 0.5;
    angleS += intensity * swirl * sin(radiusS * 10.0 + gFast);
    vec2 qSwirl = vec2(cos(angleS), sin(angleS)) * radiusS;
    vec2 uvSwirl = qSwirl * vec2(1.0, iResolution.x / iResolution.y) + center;

    vec4 texSwirl = texture(samp, uvSwirl);
    float fluctuation = sin(gFast * 2.0) * 0.5 + 0.5;
    vec3 xorPalette = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), fluctuation);
    xorPalette = mix(xorPalette, neonPalette(gFast), 0.5);
    vec4 fluctuatedColor = vec4(xorPalette, 1.0);
    vec4 xorResult = xor_RGB(texSwirl, fluctuatedColor);
    vec3 xorMix = mix(texSwirl.rgb, xorResult.rgb, 0.6);

    float xorStrength = (0.25 + 0.35 * pulse) * vign * mix(0.4, 1.4, gAmp01);
    xorStrength = clamp(xorStrength, 0.0, 1.0);

    vec3 finalRGB = mix(finalCore, xorMix, xorStrength);

    color = vec4(finalRGB, baseTex.a);
}
