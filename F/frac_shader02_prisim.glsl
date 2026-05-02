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
    float ph = fract(t * 0.05);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3) * 1.05;
}

vec3 warpTexture(vec2 baseUV, float seg, float zoom, float t, vec2 m, float aspect, float aMix, float sr, float spinAngle) {
    vec2 ar = vec2(aspect, 1.0);
    vec2 kUV = reflectUV(baseUV, seg, m, aspect);
    kUV = fractalFold(kUV, zoom, t, m, aspect);
    kUV = rotateUV(kUV, spinAngle, m, aspect);

    vec2 dir = (kUV - m) * ar;
    float r = length(dir);

    float ripple = sin(20.0 * r - t * 9.0) * 0.012 / (1.0 + 18.0 * r);
    ripple *= 1.0 / (1.0 + 12.0 * (abs(dFdx(r)) + abs(dFdy(r))));
    ripple = sin(ripple * pingPong(time_f * PI, 3.0));

    vec2 nDir = normalize(dir + 1e-5);
    vec2 uA = kUV + nDir * ripple;
    vec2 uB = mix(baseUV, kUV, 0.88);
    vec2 uC = mix(baseUV, kUV, 0.94) + vec2(0.002 * sin(t), 0.002 * cos(t));

    vec4 t1 = textureGrad(samp, fract(uA), dFdx(uA), dFdy(uA));
    vec4 t2 = textureGrad(samp, fract(uB), dFdx(uB), dFdy(uB));
    vec4 t3 = textureGrad(samp, fract(uC), dFdx(uC), dFdy(uC));

    float ampNorm = clamp(aMix * 0.12, 0.0, 1.5);
    float hueBase = fract(t * 0.06 + r * 0.22 + ampNorm * 0.3);
    float sat = 0.75 + 0.20 * sin(t * 0.4 + sr * 0.7 + ampNorm * 0.4);
    float val = 0.70 + 0.35 * sin(t * 0.55 + r * 1.9 + ampNorm * 0.5);

    vec3 tint = hsv2rgb(vec3(hueBase, sat, val));
    vec3 neon = neonPalette(t + r * 2.0 + ampNorm);

    float mix1 = 0.5 + 0.5 * sin(t * 0.6 + ampNorm * 0.3);
    float mix2 = 0.5 + 0.5 * cos(t * 0.45 + ampNorm * 0.5);

    vec3 warpCol = mix(t1.rgb, t2.rgb, mix1);
    warpCol = mix(warpCol, t3.rgb, mix2 * 0.7);
    warpCol *= tint * neon;
    warpCol *= 1.1 + 0.7 * clamp(aMix * 0.1, 0.0, 1.0);

    vec3 baseTex = textureGrad(samp, baseUV, dFdx(baseUV), dFdy(baseUV)).rgb;
    float warpMix = 0.55 + 0.35 * clamp(aMix * 0.08, 0.0, 1.0);
    vec3 combined = mix(baseTex, warpCol * 1.9, warpMix);

    vec3 bloom = combined * combined * 0.12 + pow(max(combined - 0.6, 0.0), vec3(2.0)) * 0.08;
    combined += bloom;

    return combined;
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5 ? (iMouse.xy / iResolution) : vec2(0.5));

    float t = time_f + iTime * (PI / 2.0);
    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);
    float ampNorm = clamp(aMix * 0.12, 0.0, 1.5);

    float osc = 0.5 + 0.5 * sin(t * 0.35 + 0.2 * sr + ampNorm * 0.2);
    float seg = 4.0 + 2.0 * sin(t * 0.25) + 2.5 * clamp(ampNorm, 0.0, 2.0);
    float zoom = mix(1.1, 2.3 + ampNorm * 0.4, osc);
    float spinAngle = osc * 2.0 * PI * (0.6 + 0.4 * clamp(ampNorm, 0.0, 1.5));

    vec2 centerPx = iResolution * 0.5;
    vec2 texCoordPx = tc * iResolution;
    vec2 deltaPx = texCoordPx - centerPx;
    float dist = length(deltaPx);

    float radius = 0.45 + 0.3 * clamp(ampNorm * 0.7, 0.0, 1.0);
    float maxRadius = min(iResolution.x, iResolution.y) * radius;

    float scaleFactor = 1.0 - pow(clamp(dist / maxRadius, 0.0, 1.0), 2.0);
    scaleFactor *= 1.0 + 0.9 * clamp(ampNorm, 0.0, 1.5);
    scaleFactor = clamp(scaleFactor, 0.0, 1.9);

    vec2 dirN = dist > 0.0 ? deltaPx / dist : vec2(0.0);

    float offsetBase = mix(0.008, 0.03, clamp(ampNorm * 0.6, 0.0, 1.0));
    float offsetR = offsetBase;
    float offsetG = 0.0;
    float offsetB = -offsetBase;

    vec3 colBase = warpTexture(tc, seg, zoom, t, m, aspect, aMix, sr, spinAngle);

    vec3 colBubble = colBase;
    if (dist < maxRadius) {
        vec2 texCoordR = centerPx + deltaPx * scaleFactor + dirN * offsetR * maxRadius;
        vec2 texCoordG = centerPx + deltaPx * scaleFactor + dirN * offsetG * maxRadius;
        vec2 texCoordB = centerPx + deltaPx * scaleFactor + dirN * offsetB * maxRadius;

        vec2 uvR = clamp(texCoordR / iResolution, 0.0, 1.0);
        vec2 uvG = clamp(texCoordG / iResolution, 0.0, 1.0);
        vec2 uvB = clamp(texCoordB / iResolution, 0.0, 1.0);

        vec3 colR = warpTexture(uvR, seg, zoom, t, m, aspect, aMix, sr, spinAngle);
        vec3 colG = warpTexture(uvG, seg, zoom, t, m, aspect, aMix, sr, spinAngle);
        vec3 colB = warpTexture(uvB, seg, zoom, t, m, aspect, aMix, sr, spinAngle);

        vec3 rgbSplit = vec3(colR.r, colG.g, colB.b);

        float mask = smoothstep(maxRadius, maxRadius * 0.65, dist);
        colBubble = mix(colBase, rgbSplit, mask);
    }

    vec3 baseVideo = textureGrad(samp, tc, dFdx(tc), dFdy(tc)).rgb;
    float globalMix = 0.50 + 0.35 * clamp(ampNorm * 0.5, 0.0, 1.0);
    vec3 combined = mix(baseVideo, colBubble, globalMix);

    combined = combined / (1.0 + combined);
    combined = clamp(combined, vec3(0.0), vec3(1.0));

    color = vec4(combined, 1.0);
}
