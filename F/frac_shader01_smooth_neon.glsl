#version 330 core

in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp; 
uniform vec2 iResolution;
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

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect){
    vec2 p = uv;
    for(int i=0;i<6;i++){
        p = abs((p - c) * (zoom + 0.15*sin(t*0.35+float(i)))) - 0.5 + c;
        p = rotateUV(p, t*0.12 + float(i)*0.07, c, aspect);
    }
    return p;
}

vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 movingGradient(vec2 uv, vec2 c, float t, float aspect){
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - c) * ar;
    vec2 d = normalize(vec2(cos(t*0.27), sin(t*0.31)));
    float s = dot(p, d);
    float band = 0.5 + 0.5*sin(s*6.28318530718*0.35 + t*0.9);
    float h = fract(s*0.22 + t*0.07 + 0.15*sin(t*0.33));
    float S = 0.75 + 0.25*sin(t*0.21 + s*2.0);
    float V = 0.75 + 0.25*band;
    vec3 base = hsv2rgb(vec3(h, S, V));
    float edge = smoothstep(0.2, 0.8, band);
    return mix(base*0.6, base, edge);
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect){
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if(p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + c;
}

float diamondRadius(vec2 p){
    p = abs(p);
    return max(p.x, p.y);
}

float luma(vec3 c){ return dot(c, vec3(0.299,0.587,0.114)); }

vec3 bilateral9(vec2 uv, float radiusScale, float sigma_r){
    vec2 texel = 1.0 / iResolution;
    vec2 o = texel * radiusScale;
    vec3 c0 = texture(samp, uv).rgb;
    float L0 = luma(c0);
    vec2 offs[9] = vec2[](
        vec2(0,0),
        vec2( o.x, 0), vec2(-o.x, 0),
        vec2(0,  o.y), vec2(0, -o.y),
        vec2( o.x,  o.y), vec2(-o.x,  o.y),
        vec2( o.x, -o.y), vec2(-o.x, -o.y)
    );
    float wsum = 0.0;
    vec3 acc = vec3(0.0);
    for(int i=0;i<9;i++){
        vec3 c = texture(samp, uv + offs[i]).rgb;
        float dl = luma(c) - L0;
        float wr = exp(-(dl*dl)/(2.0*sigma_r*sigma_r));
        float dsq = dot(offs[i]/texel, offs[i]/texel);
        float ws = exp(-dsq/(2.0*1.0*1.0));
        float w = wr*ws;
        acc += c*w;
        wsum += w;
    }
    return acc / max(wsum, 1e-6);
}

float localVar9(vec2 uv, float radiusScale){
    vec2 texel = 1.0 / iResolution;
    vec2 o = texel * radiusScale;
    float m = 0.0;
    float s = 0.0;
    int n = 0;
    for(int y=-1;y<=1;y++){
        for(int x=-1;x<=1;x++){
            vec3 c = texture(samp, uv + vec2(x,y)*o).rgb;
            float L = luma(c);
            m += L;
            s += L*L;
            n++;
        }
    }
    m /= float(n);
    s /= float(n);
    return max(s - m*m, 0.0);
}

void main(){
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;
    vec4 originalTexture = texture(samp, tc);

    float seg = 4.0 + 2.0*sin(time_f*0.33);
    vec2 kUV = reflectUV(uv, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.45 + 0.55 * sin(time_f * 0.42);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * 0.23, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = p;
    q = abs(q);
    if(q.y > q.x) q = q.yx;

    float base = 1.82 + 0.18*sin(time_f*0.2);
    float period = log(base);
    float tz = time_f * 0.65;
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35*sin(rD*18.0 + time_f*0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap*1.045) / ar + m);
    vec2 u2 = fract((pwrap*0.955) / ar + m);

    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(time_f*1.3)) * vec2(1.0, 1.0/aspect);

    float hue = fract(ang*0.25 + time_f*0.08 + k*0.5);
    float sat = 0.75 - 0.25*cos(time_f*0.7 + rD*10.0);
    float val = 0.8 + 0.2*sin(time_f*0.9 + k*6.28318530718);
    vec3 tint = hsv2rgb(vec3(hue, sat, val));

    float ring = smoothstep(0.0, 0.7, sin(log(rD+1e-3)*9.5 + time_f*1.2));
    float pulse = 0.5 + 0.5*sin(time_f*2.0 + rD*28.0 + k*12.0);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((tc - m)*ar));
    vign = mix(0.85, 1.2, vign);

    float blendFactor = 0.58;

    float v0 = localVar9(u0, 1.0);
    float v1 = localVar9(u1, 1.0);
    float v2 = localVar9(u2, 1.0);
    float pix = (v0+v1+v2)/3.0;

    float sStrong = smoothstep(0.02, 0.20, pix);
    float radA = mix(0.75, 2.25, sStrong);
    float sigma_r = mix(0.10, 0.22, sStrong);

    vec3 bc0 = bilateral9(u0 + off, radA, sigma_r);
    vec3 bc1 = bilateral9(u1,       radA, sigma_r);
    vec3 bc2 = bilateral9(u2 - off, radA, sigma_r);

    float rC = bc0.r;
    float gC = bc1.g;
    float bC = bc2.b;
    vec3 kaleidoRGB = vec3(rC, gC, bC);

    vec4 kaleidoColor = vec4(kaleidoRGB, 1.0) * vec4(tint, 1.0);
    vec4 merged = mix(kaleidoColor, originalTexture, blendFactor);

    merged.rgb *= (0.75 + 0.25*ring) * (0.85 + 0.15*pulse) * vign;

    vec3 bloom = merged.rgb * merged.rgb * 0.18 + pow(max(merged.rgb-0.6,0.0), vec3(2.0))*0.12;
    vec3 outCol = merged.rgb + bloom;

    float wob = 0.9 + 0.1*sin(time_f + rD*14.0 + k*9.0);
    outCol *= wob;

    vec3 grad = movingGradient(tc, m, time_f, aspect);
    float gradBase = 0.35 + 0.25*sin(time_f*0.5 + rD*7.0 + k*9.0);
    float gradAmt = mix(gradBase*0.5, 0.95, sStrong);
    vec3 screenBlend = 1.0 - (1.0 - outCol) * (1.0 - grad);
    outCol = mix(outCol, screenBlend, gradAmt);

    vec4 t = texture(samp, tc);
    outCol = mix(outCol, outCol*t.rgb, 0.8);

    float lum = dot(outCol, vec3(0.299, 0.587, 0.114));
    float tHue = time_f * 0.15 + uamp * 0.1;
    float hueBase = fract(lum * 0.8 + tHue);
    vec3 neon1 = hsv2rgb(vec3(hueBase, 1.0, 1.0));
    vec3 neon2 = hsv2rgb(vec3(fract(hueBase + 0.33), 1.0, 1.0));
    float wave = pingPong(time_f * 0.25 + amp * 2.0, 1.0);
    vec3 neon = mix(neon1, neon2, wave);

    float audio = clamp(amp * 1.5 + uamp * 0.25, 0.0, 1.5);
    float strength = clamp(0.2 + audio, 0.0, 1.0);

    vec3 mixed = mix(outCol, neon, strength);
    mixed = pow(mixed, vec3(0.8));
    mixed = clamp(mixed, 0.0, 1.0);

    color = vec4(mixed, 1.0);
}
