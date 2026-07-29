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
uniform vec2 iMouseClick;
uniform float iSampleRate;

const float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length){
    float m = mod(x, length*2.0);
    return m <= length ? m : length*2.0 - m;
}

float luma(vec3 c){ return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

vec3 hue(float t){
    return clamp(vec3(abs(t*6.0-3.0)-1.0, 2.0-abs(t*6.0-2.0), 2.0-abs(t*6.0-4.0)),0.0,1.0);
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect){
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 rippleDisplace(vec2 uv, vec2 center, float aspect, float t, float drive){
    vec2 d = uv - center;
    float dist = length(d);
    vec2 dir = d / max(dist, 1e-6);
    float baseWave = 0.055;
    float baseAmp  = 0.018;
    float speed    = 1.35;
    vec3 tx = textureGrad(samp, uv, dFdx(uv), dFdy(uv)).rgb;
    float waveLength = baseWave * (0.9 + 0.5*luma(tx));
    float amplitude  = baseAmp  * (0.75 + 0.5*drive);
    float ripple = sin((dist / max(waveLength,1e-4) - t * speed) * 6.2831853);
    ripple *= smoothstep(0.95, 0.2, dist);
    return uv + dir * ripple * amplitude;
}

vec2 spiralTwist(vec2 uv, vec2 center, float aspect, float t, float drive){
    vec2 p = uv - center;
    p.x *= aspect;
    float r = length(p)+1e-6;
    float a = atan(p.y, p.x);
    float swirl = (0.55 + 0.5*drive) / (1.0 + 8.0*r);
    float spin  = (0.22 + 0.18*drive) * t;
    a += spin + swirl;
    float pull = 0.10 / (1.0 + 6.0*r);
    r = max(r - pull, 0.0);
    vec2 q = vec2(cos(a), sin(a)) * r;
    q.x /= aspect;
    return q + center;
}

vec3 spiralEcho(vec2 uv, vec2 center, float aspect, float t, float drive){
    const int TAPS = 6;
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    for(int i=0;i<TAPS;i++){
        float k = float(i);
        float radScale = 1.0 + 0.085*k;
        float timeLag  = 0.11*k;
        vec2 u = spiralTwist(uv, center, aspect, t - timeLag, drive);
        u = rotateUV(u, (0.12+0.04*drive)*k, center, aspect);
        vec3 s = textureGrad(samp, fract(u / radScale), dFdx(uv), dFdy(uv)).rgb;
        float w = 1.0 / (1.0 + 0.85*k);
        acc += s * w;
        wsum += w;
    }
    return acc / max(wsum, 1e-6);
}

vec3 reinhard(vec3 x){ return x/(1.0+x); }

vec3 softLimit(vec3 c, float maxY){
    float Y = luma(c);
    if(Y > maxY) c *= maxY/(Y+1e-6);
    return c;
}

void main(void){
    vec2 mouseN = iMouse.xy / iResolution;
    vec2 clickN = iMouseClick / iResolution;
    bool hasClick = max(iMouseClick.x, iMouseClick.y) > 0.0;
    vec2 center = (iMouse.z > 0.5) ? mouseN : (hasClick ? clickN : vec2(0.5));

    float t = (time_f + iTime*0.6) + float(iFrame)*0.0003;
    float aMix = clamp(amp*0.7 + uamp*0.3, 0.0, 12.0);
    float drive = tanh(aMix*0.07);
    float aspect = iResolution.x / iResolution.y;

    vec2 uvRipple = rippleDisplace(tc, center, aspect, t, drive);
    vec3 echoCol = spiralEcho(uvRipple, center, aspect, t, drive);

    vec2 m = (iMouse.z > 0.0) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    float a = time_f*0.45;
    vec2 dir = normalize(vec2(cos(a), sin(a)));
    float span = 0.22 + 0.10*sin(time_f*0.35);
    vec2 startP = m - dir*span;
    vec2 endP   = m + dir*span;
    vec2 ab = endP - startP;
    float L = max(length(ab), 1e-4);
    vec2 u = ab / L;
    float gradT = clamp(dot(tc - startP, u) / L, 0.0, 1.0);
    vec3 c0 = hue(fract(time_f*0.08));
    vec3 c1 = hue(fract(time_f*0.08 + 0.5));
    vec3 grad = mix(c0, c1, gradT);

    vec3 tex = textureGrad(samp, uvRipple, dFdx(uvRipple), dFdy(uvRipple)).rgb;
    vec3 mixed = mix(tex, echoCol, 0.6);
    float colorMix = 0.55*clamp(amp, 0.0, 1.0);
    mixed = mix(mixed, mixed * grad, colorMix);

    float satAmt = 1.08 + 0.18*drive;
    float Y = luma(mixed);
    mixed = mix(vec3(Y), mixed, satAmt);

    mixed *= 1.08 + 0.15*drive;
    mixed = softLimit(mixed, 0.9);
    mixed = reinhard(mixed);
    mixed = pow(clamp(mixed,0.0,1.0), vec3(0.95));

    color = vec4(mixed, 1.0);
}
