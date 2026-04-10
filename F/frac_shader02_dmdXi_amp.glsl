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

float gAmp01;
float gInst01;
float gSlow;
float gFast;
float gDetail;

float pingPong(float x, float length){
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect){
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect){
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

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect){
    vec2 p = uv;
    for(int i = 0; i < 6; i++){
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

vec3 neonPalette(float t){
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

vec3 limitHighlights(vec3 c){
    float m = max(c.r, max(c.g, c.b));
    if(m > 0.9) c *= 0.9 / m;
    return c;
}

void main(void){
    float aAcc = clamp(amp, 0.0, 20.0);
    float aInst = clamp(uamp, 0.0, 20.0);
    float aMix = clamp(aAcc * 0.7 + aInst * 0.3, 0.0, 20.0);
    gAmp01 = clamp(aMix / 8.0, 0.0, 1.0);
    gInst01 = clamp(aInst / 8.0, 0.0, 1.0);

    float tGlobal = time_f + iTime;
    float fpsNorm = clamp(iFrameRate / 60.0, 0.4, 2.5);
    float t = tGlobal * fpsNorm;

    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float chT0 = iChannelTime[0];
    vec2 chRes0 = iChannelResolution[0].xy;
    float chAspect = (chRes0.y > 0.0) ? chRes0.x / chRes0.y : (iResolution.x / iResolution.y);

    float framePhase = float(iFrame) * 0.009 + iTimeDelta * 3.0;
    float frameJitter = sin(framePhase) * 0.004;

    float datePhase = iDate.y * 0.13 + iDate.z * 0.03 + iDate.w * 0.001;

    gSlow   = t * mix(0.18, 0.7, gAmp01);
    gFast   = t * mix(0.7,  4.0, gAmp01);
    gDetail = t * mix(0.35, 2.3, gAmp01);

    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);

    vec2 baseCenter = (iMouse.z > 0.5 ? (iMouse.xy / iResolution) : vec2(0.5));
    vec2 clickCenter = (iMouseClick.x > 0.0 || iMouseClick.y > 0.0)
        ? (iMouseClick / iResolution)
        : baseCenter;
    float clickMix = 0.25 + 0.35 * smoothstep(0.2, 1.0, gAmp01);
    vec2 m = mix(baseCenter, clickCenter, clickMix);

    float aspect = ar.x;

    vec2 uv0 = tc * 2.0 - 1.0;
    uv0.x *= aspect;
    float baseR = length(uv0);

    float segBase = 4.0 + 2.0 * sin(gSlow * 0.25 + datePhase);
    float segAmp = 3.0 * gAmp01 + 4.0 * gInst01;
    float seg = segBase + segAmp * sin(gFast * 0.21 + chT0 * 0.37);

    float zoomBase = 1.35 + 0.35 * sin(gSlow * 0.35 + 0.2 * sr);
    float zoomAmp = 0.5 + 0.9 * gAmp01;
    float zoom = zoomBase + zoomAmp * sin(gFast * 0.27 + baseR * 2.0 + framePhase);

    vec2 kUV = reflectUV(tc, seg, m, aspect);
    kUV = fractalFold(kUV, zoom, gDetail, m, aspect);
    kUV = rotateUV(kUV, gSlow * 0.22 + gInst01 * 1.3, m, aspect + 0.2 * (chAspect - aspect));

    vec2 dir = (kUV - m) * ar;
    float r = length(dir);

    float rippleAmp = mix(0.006, 0.02, gAmp01) * (0.7 + 0.6 * gInst01);
    float rippleFreq = 18.0 + 6.0 * gAmp01 + 8.0 * gInst01;
    float rippleTime = gFast * (0.8 + 0.4 * gInst01 * sr);
    float ripple = sin(rippleFreq * r - rippleTime) * rippleAmp / (1.0 + 18.0 * r);
    ripple *= 1.0 / (1.0 + 12.0 * (abs(dFdx(r)) + abs(dFdy(r))));
    ripple += frameJitter * 0.4;

    vec2 dirN = normalize(dir + 1e-5);
    vec2 uA = kUV + dirN * ripple;
    vec2 uB = mix(tc, kUV, 0.84 + 0.08 * gAmp01);
    vec2 jitter = vec2(0.002 * sin(t + framePhase), 0.002 * cos(t * 0.91 + framePhase * 1.3));
    jitter *= (0.6 + 0.8 * gInst01);
    vec2 uC = mix(tc, kUV, 0.93) + jitter;

    vec4 t1 = textureGrad(samp, fract(uA), dFdx(uA), dFdy(uA));
    vec4 t2 = textureGrad(samp, fract(uB), dFdx(uB), dFdy(uB));
    vec4 t3 = textureGrad(samp, fract(uC), dFdx(uC), dFdy(uC));

    float hueBase = fract(gSlow * 0.04 + chT0 * 0.05 + datePhase * 0.1);
    float sat = 0.65 + 0.25 * sin(gSlow * 0.4 + sr + gAmp01 * 2.0);
    float val = 0.6 + 0.3 * sin(gFast * 0.35 + dot(tc, vec2(2.3, 1.9)) + gInst01 * 3.0);
    vec3 tint = hsv2rgb(vec3(hueBase + r * 0.25, sat, val));

    float slowBeat = 0.5 + 0.5 * sin(gSlow * 0.8 + aMix * 0.05);
    float mix1 = 0.5 + 0.5 * sin(gFast * 0.6 + chT0 * 0.3);
    float mix2 = 0.5 + 0.5 * cos(gSlow * 0.45 + framePhase);

    vec3 warpCol = mix(t1.rgb, t2.rgb, mix1);
    warpCol = mix(warpCol, t3.rgb, mix2 * (0.4 + 0.4 * gAmp01));
    float gain = mix(0.9, 1.5, gAmp01) * (0.9 + 0.3 * slowBeat);
    warpCol *= tint * gain;

    vec3 base = textureGrad(samp, tc, dFdx(tc), dFdy(tc)).rgb;

    float warpMix = 0.45 + 0.35 * gAmp01;
    vec3 combined = mix(base, warpCol, warpMix);

    vec3 bloom = combined * combined * 0.08
               + pow(max(combined - 0.6, 0.0), vec3(2.0)) * 0.05;
    combined += bloom;

    combined = limitHighlights(combined);
    combined = clamp(combined, vec3(0.0), vec3(1.0));

    color = vec4(combined, 1.0);
}
