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

vec3 hsv2rgb(vec3 c){
    vec4 K=vec4(1.0,2.0/3.0,1.0/3.0,3.0);
    vec3 p=abs(fract(c.xxx+K.xyz)*6.0-K.www);
    return c.z*mix(K.xxx,clamp(p-K.xxx,0.0,1.0),c.y);
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
    for(int i=0;i<6;i++){
        p = abs((p - c) * (zoom + 0.15*sin(t*0.35+float(i)))) - 0.5 + c;
        p = rotateUV(p, t*0.12 + float(i)*0.07, c, aspect);
    }
    return p;
}

vec3 neonPalette(float t){
    vec3 pink  = vec3(1.0, 0.35, 0.85);
    vec3 blue  = vec3(0.20, 0.60, 1.0);
    vec3 green = vec3(0.25, 1.00, 0.55);
    float ph = fract(t*0.08);
    vec3 k1 = mix(pink,  blue,  smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue,  green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink,  smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a*k1 + b*k2 + c*k3);
}

vec3 tentBlur3(sampler2D img, vec2 uv, vec2 res){
    vec2 ts = 1.0 / res;
    vec3 s00 = texture(img, uv + ts*vec2(-1.0,-1.0)).rgb;
    vec3 s10 = texture(img, uv + ts*vec2( 0.0,-1.0)).rgb;
    vec3 s20 = texture(img, uv + ts*vec2( 1.0,-1.0)).rgb;
    vec3 s01 = texture(img, uv + ts*vec2(-1.0, 0.0)).rgb;
    vec3 s11 = texture(img, uv).rgb;
    vec3 s21 = texture(img, uv + ts*vec2( 1.0, 0.0)).rgb;
    vec3 s02 = texture(img, uv + ts*vec2(-1.0, 1.0)).rgb;
    vec3 s12 = texture(img, uv + ts*vec2( 0.0, 1.0)).rgb;
    vec3 s22 = texture(img, uv + ts*vec2( 1.0, 1.0)).rgb;
    return (s00 + 2.0*s10 + s20 + 2.0*s01 + 4.0*s11 + 2.0*s21 + s02 + 2.0*s12 + s22) / 16.0;
}

vec3 preBlendColor(vec2 uv){
    vec3 tex = tentBlur3(samp, uv, iResolution);
    vec3 neon = neonPalette(time_f);
    return mix(tex, neon, 0.4);
}

float diamondRadius(vec2 p){
    p = abs(p);
    return max(p.x, p.y);
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect){
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if(p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + c;
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
    vec4 baseTex = texture(samp, tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    float t = time_f + iTime*0.5;

    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 3.0);
    float pulse = 0.5 + 0.5*sin(t*2.0 + aMix*2.0);
    float seg = 4.0 + 2.0*sin(t*0.33);
    vec2 kUV = reflectUV(tc, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.45 + 0.55 * sin(t * 0.42);
    kUV = fractalFold(kUV, foldZoom, t, m, aspect);
    kUV = rotateUV(kUV, t * 0.23, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec3 baseCol = preBlendColor(tc);
    vec3 glowCol = preBlendColor(kUV);
    glowCol *= (0.85 + 0.15*pulse);

    float auraDist = length((tc - m)*ar);
    float auraStrength = smoothstep(0.6, 0.1, auraDist);
    vec3 auraColor = vec3(1.0, 0.6, 0.85); 
    auraColor *= (0.6 + 0.4*sin(t*1.2 + amp));
    auraColor *= 0.4; 

    vec3 outCol = mix(baseCol, glowCol, 0.7);
    outCol += auraColor * auraStrength;
    outCol = aces(outCol);

    color = vec4(outCol, baseTex.a);
}
