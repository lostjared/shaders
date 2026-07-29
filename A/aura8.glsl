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
    float m = mod(x, length*2.0);
    return m <= length ? m : length*2.0 - m;
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

float luma(vec3 c){ return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 neonPalette(float t){
    vec3 a = vec3(1.00, 0.20, 0.80);
    vec3 b = vec3(0.10, 0.65, 1.00);
    vec3 c = vec3(0.15, 1.00, 0.55);
    float ph = fract(t*0.12);
    vec3 k1 = mix(a, b, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(b, c, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(c, a, smoothstep(0.66, 1.00, ph));
    float s1 = step(ph, 0.33);
    float s2 = step(0.33, ph) * step(ph, 0.66);
    float s3 = step(0.66, ph);
    vec3 outc = s1*k1 + s2*k2 + s3*k3;
    return normalize(outc + 1e-6);
}

vec3 tentBlur3RGB(sampler2D img, vec2 uv, vec2 res){
    vec2 ts = 1.0 / res;
    vec3 s00 = textureGrad(img, uv + ts*vec2(-1.0,-1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s10 = textureGrad(img, uv + ts*vec2( 0.0,-1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s20 = textureGrad(img, uv + ts*vec2( 1.0,-1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s01 = textureGrad(img, uv + ts*vec2(-1.0, 0.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s11 = textureGrad(img, uv, dFdx(uv), dFdy(uv)).rgb;
    vec3 s21 = textureGrad(img, uv + ts*vec2( 1.0, 0.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s02 = textureGrad(img, uv + ts*vec2(-1.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s12 = textureGrad(img, uv + ts*vec2( 0.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    vec3 s22 = textureGrad(img, uv + ts*vec2( 1.0, 1.0), dFdx(uv), dFdy(uv)).rgb;
    return (s00 + 2.0*s10 + s20 + 2.0*s01 + 4.0*s11 + 2.0*s21 + s02 + 2.0*s12 + s22) / 16.0;
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

vec3 contrastCurve(vec3 c, float k){
    c = clamp(c, 0.0, 1.0);
    return clamp((c-0.5)*(1.0+k)+0.5, 0.0, 1.0);
}

/* Spiral twist field driven by texture luminance and audio */
vec2 spiralTwist(vec2 uv, vec2 center, float aspect, float t, float drive){
    vec2 p = uv - center;
    p.x *= aspect;
    float r = length(p)+1e-6;
    float a = atan(p.y, p.x);

    vec3 tex = textureGrad(samp, uv, dFdx(uv), dFdy(uv)).rgb;
    float lum = luma(tex);

    float swirl = (0.65 + 0.85*drive) * (1.0 + 0.6*lum) / (1.0 + 8.0*r);
    float spin  = (0.35 + 0.25*drive) * t;

    a += spin + swirl;
    float pull = (0.12 + 0.25*drive*lum) / (1.0 + 6.0*r);
    r = max(r - pull, 0.0);

    vec2 q = vec2(cos(a), sin(a)) * r;
    q.x /= aspect;
    return q + center;
}

/* Multitap echo that samples along the spiral at expanding radii */
vec3 spiralEcho(vec2 uv, vec2 center, float aspect, float t, float drive){
    const int TAPS = 7;
    vec3 acc = vec3(0.0);
    float wsum = 0.0;

    float baseHue = fract(t*0.05);
    vec3 neon = neonPalette(t*0.6);

    for(int i=0;i<TAPS;i++){
        float k = float(i);
        float radScale = 1.0 + 0.08*k + 0.05*drive*k;
        float timeLag  = 0.08*k;
        vec2 u = spiralTwist(uv, center, aspect, t - timeLag, drive);
        u = rotateUV(u, (0.12+0.06*drive)*k, center, aspect);

        vec2 dir = (u-center);
        dir.x *= aspect;
        float r = length(dir)+1e-6;
        float chroma = (0.0015 + 0.0012*drive) * (0.8 + 0.6*exp(-r*3.0));
        vec2 off = normalize(dir) * chroma * vec2(1.0, 1.0/aspect);

        vec3 sR = textureGrad(samp, fract(mix(uv, u, 0.85)/radScale + off), dFdx(uv), dFdy(uv)).rgb;
        vec3 sG = textureGrad(samp, fract(mix(uv, u, 0.85)/radScale           ), dFdx(uv), dFdy(uv)).rgb;
        vec3 sB = textureGrad(samp, fract(mix(uv, u, 0.85)/radScale - off), dFdx(uv), dFdy(uv)).rgb;
        vec3 s = vec3(sR.r, sG.g, sB.b);

        float lum = luma(s);
        vec3 colorize = mix(s, s*neon, 0.35 + 0.25*drive*lum);

        float w = 1.0 / (1.0 + 0.9*k);
        acc += colorize * w;
        wsum += w;
    }
    return acc / max(wsum, 1e-6);
}

void main(void){
    vec4 baseTex = texture(samp, tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);

    vec2 mouseN = iMouse.xy / iResolution;
    vec2 clickN = iMouseClick / iResolution;
    bool hasClick = max(iMouseClick.x, iMouseClick.y) > 0.0;

    vec2 center = (iMouse.z > 0.5) ? mouseN : (hasClick ? clickN : vec2(0.5));

    float t = time_f + iTime*0.75 + float(iFrame)*0.0005;
    float daySeed = iDate.x*37.0 + iDate.y*17.0 + iDate.z*7.0 + iDate.w;
    t += daySeed*0.013;

    float sr = clamp(iSampleRate/48000.0, 0.25, 4.0);
    float aMix = clamp(amp*0.7 + uamp*0.3, 0.0, 20.0);
    float drive = clamp(aMix*0.10, 0.0, 3.0);

    float seg = clamp(4.0 + 3.0*sin(t*0.33 + 0.1*sr), 3.0, 12.0);
    vec2 kUV = reflectUV(tc, seg, center, aspect);

    vec3 echoCol = spiralEcho(kUV, center, aspect, t, drive);

    vec3 local = tentBlur3RGB(samp, tc, iResolution);
    float mixDetail = 0.25 + 0.25*sin(t*0.7 + drive*0.8);
    vec3 mixCol = mix(local, echoCol, 0.65 + mixDetail);

    float r = length((tc - center)*ar);
    float ring = smoothstep(0.95, 0.45, r + 0.05*sin(8.0*r - t*2.0 - drive*3.0));
    vec3 glow = neonPalette(t) * (0.35 + 0.35*pingPong(t + drive, 2.5));

    vec3 outCol = mixCol + glow*ring;

    outCol = contrastCurve(outCol, 0.55 + 0.25*drive);
    float exposure = 1.25 + 0.35*drive;
    outCol *= exposure;

    outCol = clamp(outCol, 0.0, 3.0);
    outCol = aces(outCol);

    float focus = smoothstep(0.0, 1.0, 1.0 - r*1.05);
    vec3 finalRGB = mix(baseTex.rgb, outCol, 0.70 + 0.25*focus);

    color = vec4(finalRGB, baseTex.a);
}
