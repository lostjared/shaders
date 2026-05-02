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
        float z = zoom + 0.15 * sin(t * 0.35 + float(i));
        p = abs((p - c) * z) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

void main(void) {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);

    vec2 m = (iMouse.z > 0.5 ? (iMouse.xy / iResolution) : vec2(0.5));
    m += (iMouseClick / iResolution) * 0.1;

    float t = time_f + iTime * (PI / 2.0);
    float rate = max(iFrameRate, 1.0);
    float sr = clamp((iSampleRate / 48000.0) * (rate / 60.0), 0.25, 4.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);

    float chanAspect = iChannelResolution[0].y > 0.0
                           ? iChannelResolution[0].x / iChannelResolution[0].y
                           : 1.0;
    float chanBeat = 0.5 + 0.5 * sin(iChannelTime[0] * 0.5 + iDate.x * 0.1);

    float loopDuration = 25.0;
    float currentTime = mod(time_f + float(iFrame) * 0.01, loopDuration);
    float zoomPing = pingPong((time_f + iTimeDelta * 60.0) * 0.25 + chanBeat, 1.0);

    vec2 normCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    normCoord.x = abs(normCoord.x);
    float dist = length(normCoord);
    dist = clamp(dist, 0.0, 1.4);

    float angle = atan(normCoord.y, normCoord.x);
    float spiralSpeed = 5.0;
    float inwardBase = currentTime / loopDuration;
    float inwardSpeed = mix(inwardBase, zoomPing, 0.5);

    float edgeFade = 1.0 - smoothstep(0.0, 8.0, dist);
    angle += edgeFade * currentTime * spiralSpeed * (0.6 + 0.4 * chanBeat);

    dist *= 1.0 - inwardSpeed;
    float distWarp = tan(dist * (0.4 + 0.3 * zoomPing));
    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * distWarp;
    spiralCoord = (spiralCoord / vec2(iResolution.x / iResolution.y, 1.0) + 1.0) * 0.5;

    vec2 baseUV = mix(tc, spiralCoord, 0.75);
    baseUV = fract(baseUV);

    float osc = 0.5 + 0.5 * sin(t * 0.35 + 0.2 * sr + iDate.y * 0.01);
    float seg = 4.0 + 2.0 * sin(t * 0.25 + chanAspect * 0.2);
    float zoomBase = mix(1.1, 2.1, osc);
    float zoom = zoomBase * (0.7 + 1.8 * zoomPing);

    float spinAngle = osc * 2.0 * PI * (0.8 + 0.4 * chanBeat);

    vec2 kUV = reflectUV(baseUV, seg, m, ar.x);
    kUV = fractalFold(kUV, zoom, t, m, ar.x);
    kUV = rotateUV(kUV, spinAngle, m, ar.x);

    vec2 dir = (kUV - m) * ar;
    float r = length(dir);

    float ripple = sin(20.0 * r - t * 9.0 - iDate.z * 0.02) * 0.012 / (1.0 + 18.0 * r);
    ripple *= 1.0 / (1.0 + 12.0 * (abs(dFdx(r)) + abs(dFdy(r))));
    ripple = sin(ripple * pingPong(time_f * PI + chanBeat, 3.0 + 1.5 * zoomPing));

    ripple *= 1.0 + 0.6 * sin(aMix * 0.1 + iTimeDelta * 10.0);

    vec2 uA = kUV + normalize(dir + 1e-5) * ripple;
    vec2 uB = mix(baseUV, kUV, 0.88);
    vec2 uC = mix(baseUV, kUV, 0.94) + vec2(0.002 * sin(t + iDate.w * 0.05), 0.002 * cos(t + iTimeDelta * 5.0));

    vec2 fA = fract(uA);
    vec2 fB = fract(uB);
    vec2 fC = fract(uC);

    vec4 t1 = textureGrad(samp, fA, dFdx(fA), dFdy(fA));
    vec4 t2 = textureGrad(samp, fB, dFdx(fB), dFdy(fB));
    vec4 t3 = textureGrad(samp, fC, dFdx(fC), dFdy(fC));

    float hueBase = fract(t * 0.06 + iDate.x * 0.01);
    float sat = 0.7 + 0.25 * sin(t * 0.4 + sr + chanBeat);
    float val = 0.6 + 0.35 * sin(t * 0.5 + dot(baseUV, vec2(2.3, 1.9)) + iFrame * 0.002);

    vec3 tint = hsv2rgb(vec3(hueBase + r * 0.25, sat, val));

    float slowBeat = 0.5 + 0.5 * sin(t * 0.8 + aMix * 0.05 + chanBeat);
    float mix1 = 0.5 + 0.5 * sin(t * 0.6 + zoomPing * PI);
    float mix2 = 0.5 + 0.5 * cos(t * 0.45 + inwardBase * PI);

    vec3 warpCol = mix(t1.rgb, t2.rgb, mix1);
    warpCol = mix(warpCol, t3.rgb, mix2 * 0.5);
    warpCol *= tint * (0.92 + 0.08 * slowBeat);

    vec3 baseTex = textureGrad(samp, tc, dFdx(tc), dFdy(tc)).rgb;
    vec3 spiralTex = textureGrad(samp, spiralCoord, dFdx(spiralCoord), dFdy(spiralCoord)).rgb;
    vec3 spiralMix = mix(baseTex, spiralTex, 0.7 + 0.3 * zoomPing);

    vec3 combined = mix(spiralMix, warpCol * 3.0, 0.6);

    vec3 bloom = combined * combined * 0.18 + pow(max(combined - 0.6, 0.0), vec3(2.0)) * 0.10;
    combined += bloom;

    combined = clamp(combined, vec3(0.0), vec3(1.0));
    color = vec4(combined, 1.0);
}
