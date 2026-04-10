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

vec2 inwardSpiral(vec2 uv, vec2 c, float aspect, float t){
    vec2 p = uv - c;
    p.x *= aspect;
    float r = length(p) + 1e-6;
    float ang = atan(p.y, p.x);
    float spin = -0.65 * t;
    float swirl = -1.35 / (1.0 + 10.0 * r);
    ang += spin + swirl;
    float pull = 0.18 / (1.0 + 8.0 * r);
    r = max(r - pull, 0.0);
    vec2 q = vec2(cos(ang), sin(ang)) * r;
    q.x /= aspect;
    return q + c;
}

vec3 satBoost(vec3 c, float s){
    float l = dot(c, vec3(0.2126,0.7152,0.0722));
    return mix(vec3(l), c, 1.0 + s);
}

vec3 vibrance(vec3 c, float v){
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    float sat = mx - mn;
    float amt = 1.0 + v * (1.0 - sat);
    float l = dot(c, vec3(0.2126,0.7152,0.0722));
    return mix(vec3(l), c, amt);
}

vec3 screen(vec3 a, vec3 b){
    return 1.0 - (1.0 - a)*(1.0 - b);
}

vec3 aces(vec3 x){
    const float a=2.51;
    const float b=0.03;
    const float c=2.43;
    const float d=0.59;
    const float e=0.14;
    x = (x*(a*x+b))/(x*(c*x+d)+e);
    return clamp(x,0.0,1.0);
}

void main(void){
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 m = (iMouse.z > 0.5 ? (iMouse.xy / iResolution) : vec2(0.5));

    float t = (time_f + iTime);
    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);

    float seg = 6.0 + 4.0 * sin(t * 0.25);
    float zoom = 1.65 + 0.55 * sin(t * 0.35 + 0.2 * sr);

    vec2 kUV = reflectUV(tc, seg, m, ar.x);
    kUV = fractalFold(kUV, zoom, t, m, ar.x);
    kUV = rotateUV(kUV, t * 0.28, m, ar.x);
    kUV = inwardSpiral(kUV, m, ar.x, t);

    vec2 dir = (kUV - m) * ar;
    float r = length(dir);
    float ripple = sin(22.0 * r - t * 9.5) * 0.013 / (1.0 + 18.0 * r);
    ripple *= 1.0 / (1.0 + 12.0 * (abs(dFdx(r)) + abs(dFdy(r))));

    vec2 uA = kUV + normalize(dir + 1e-5) * ripple;
    vec2 uB = mix(tc, kUV, 0.94);
    vec2 uC = mix(tc, kUV, 0.985) + vec2(0.0018 * sin(t), 0.0018 * cos(t));

    vec4 t1 = textureGrad(samp, fract(uA), dFdx(uA), dFdy(uA));
    vec4 t2 = textureGrad(samp, fract(uB), dFdx(uB), dFdy(uB));
    vec4 t3 = textureGrad(samp, fract(uC), dFdx(uC), dFdy(uC));

    float hueSweep = fract(t*0.07 + tc.x*0.35 + tc.y*0.18 + r*0.25);
    float hueSweep2 = fract(t*0.05 - tc.y*0.28 + tc.x*0.12 - r*0.18);
    float sat = 0.85 + 0.12*sin(t*0.6 + sr);
    vec3 gradA = hsv2rgb(vec3(hueSweep, sat, 1.0));
    vec3 gradB = hsv2rgb(vec3(hueSweep2, 0.95, 1.0));
    vec3 gradient = mix(gradA, gradB, 0.5 + 0.5*sin(t*0.4 + dot(tc, vec2(1.7,1.3))));

    float slowBeat = 0.5 + 0.5 * sin(t * 0.8 + aMix * 0.05);
    float mix1 = 0.55 + 0.45 * sin(t * 0.6);
    float mix2 = 0.55 + 0.45 * cos(t * 0.45);

    vec3 warpCol = mix(t1.rgb, t2.rgb, mix1);
    warpCol = mix(warpCol, t3.rgb, mix2 * 0.65);

    vec3 neon = screen(warpCol, gradient);
    neon = satBoost(neon, 0.65);
    neon = vibrance(neon, 0.9);
    neon = pow(max(neon, 0.0), vec3(0.9))*(1.15 + 0.1*slowBeat);

    vec3 base = textureGrad(samp, tc, dFdx(tc), dFdy(tc)).rgb;
    float patMix = clamp(0.82 + 0.16*slowBeat + 0.12*clamp(aMix*0.08,0.0,1.0), 0.0, 0.98);
    vec3 combined = mix(base, neon, patMix);

    vec3 bloom = combined*combined*0.16 + pow(max(combined-0.7,0.0), vec3(2.0))*0.10;
    combined += bloom;

    combined = aces(combined);
    color = vec4(combined, 1.0);
    color  = mix(color, texture(samp, tc), 0.8);
}
