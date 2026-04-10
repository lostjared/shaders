#version 330 core
in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float seed;

const float PI = 3.1415926535897932384626433832795;

float h1(float n){return fract(sin(n*91.345+37.12)*43758.5453123);}
vec2 h2(vec2 p){return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);}
vec2 rot(vec2 v,float a){float c=cos(a),s=sin(a);return vec2(c*v.x-s*v.y,s*v.x+c*v.y);}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 rotateUV(vec2 uv, float angle, vec2 cent, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - cent;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + cent;
}

vec2 reflectUV(vec2 uv, float segments, vec2 cent, float aspect) {
    vec2 p = uv - cent;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 6.28318530718 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + cent;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 cent, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 6; i++) {
        p = abs((p - cent) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + cent;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, cent, aspect);
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

vec3 softTone(vec3 col) {
    col = pow(max(col, 0.0), vec3(0.95));
    float l = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(l), col, 0.9);
    return clamp(col, 0.0, 1.0);
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

vec2 diamondFold(vec2 uv, vec2 cent, float aspect) {
    vec2 p = (uv - cent) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + cent;
}

void main(void){
    float a = clamp(amp,0.0,1.0);
    float ua = clamp(uamp,0.0,1.0);
    float t = time_f;

    vec2 center = vec2(0.5, 0.5);
    vec2 baseUV = tc;
    vec2 offset = baseUV - center;
    float maxRadius = length(vec2(0.5, 0.5));
    float radius = length(offset);
    float normalizedRadius = radius / maxRadius;

    float distortion = 0.25 + 0.45*ua + 0.3*a;
    float distortedRadius = normalizedRadius + distortion * normalizedRadius * normalizedRadius;
    distortedRadius = clamp(distortedRadius, 0.0, 1.0);
    distortedRadius *= maxRadius;
    vec2 normDir = radius > 0.0 ? offset / radius : vec2(0.0);
    vec2 distortedCoords = center + distortedRadius * normDir;

    float spinSpeed = 0.6 + 1.8*(0.3 + 0.7*a);
    float modulatedTime = pingPong(t * spinSpeed, 5.0);
    float angSpin = atan(distortedCoords.y - center.y, distortedCoords.x - center.x) + modulatedTime;

    vec2 rotatedTC;
    rotatedTC.x = cos(angSpin) * (distortedCoords.x - center.x) - sin(angSpin) * (distortedCoords.y - center.y) + center.x;
    rotatedTC.y = sin(angSpin) * (distortedCoords.x - center.x) + cos(angSpin) * (distortedCoords.y - center.y) + center.y;

    float warpAmp = 0.02 + 0.06*ua + 0.04*a;
    vec2 uvWarp;
    uvWarp.x = pingPong(rotatedTC.x + t * 0.12 * (1.0 + warpAmp*5.0), 1.0);
    uvWarp.y = pingPong(rotatedTC.y + t * 0.12 * (1.0 + warpAmp*5.0), 1.0);

    vec2 uv = uvWarp;

    float speedR=5.0, ampR=0.03, waveR=10.0;
    float speedG=6.5, ampG=0.025, waveG=12.0;
    float speedB=4.0, ampB=0.035, waveB=8.0;

    float rR=sin(uv.x*waveR+t*speedR)*ampR + sin(uv.y*waveR*0.8+t*speedR*1.2)*ampR;
    float rG=sin(uv.x*waveG*1.5+t*speedG)*ampG + sin(uv.y*waveG*0.3+t*speedG*0.7)*ampG;
    float rB=sin(uv.x*waveB*0.5+t*speedB)*ampB + sin(uv.y*waveB*1.7+t*speedB*1.3)*ampB;

    vec2 tcR=uv+vec2(rR,rR);
    vec2 tcG=uv+vec2(rG,-0.5*rG);
    vec2 tcB=uv+vec2(0.3*rB,rB);

    vec3 pats[4]=vec3[](vec3(1,0,1),vec3(0,1,0),vec3(1,0,0),vec3(0,0,1));
    float pspd=4.0;
    int pidx=int(mod(floor(t*pspd+seed*4.0),4.0));
    vec3 mir=pats[pidx];

    vec2 m = iMouse.z>0.5 ? (iMouse.xy/iResolution) : fract(vec2(0.37+0.11*sin(t*0.63+seed),0.42+0.13*cos(t*0.57+seed*2.0)));
    vec2 dR=tcR-m, dG=tcG-m, dB=tcB-m;

    float fallR=smoothstep(0.55,0.0,length(dR));
    float fallG=smoothstep(0.55,0.0,length(dG));
    float fallB=smoothstep(0.55,0.0,length(dB));

    float sw=(0.12+0.38*ua+0.25*a);
    vec2 tangR=rot(normalize(dR+1e-4),1.5707963);
    vec2 tangG=rot(normalize(dG+1e-4),1.5707963);
    vec2 tangB=rot(normalize(dB+1e-4),1.5707963);

    vec2 airR=tangR*sw*fallR*(0.06+0.22*a)*(0.6+0.4*cos(uv.y*40.0+t*3.0+seed));
    vec2 airG=tangG*sw*fallG*(0.06+0.22*a)*(0.6+0.4*cos(uv.y*38.0+t*3.3+seed*1.7));
    vec2 airB=tangB*sw*fallB*(0.06+0.22*a)*(0.6+0.4*cos(uv.y*42.0+t*2.9+seed*0.9));

    vec2 jit = (h2(uv*vec2(233.3,341.9)+t+seed)-0.5)*(0.0006+0.004*ua);
    tcR += airR + jit;
    tcG += airG + jit;
    tcB += airB + jit;

    vec2 fR=vec2(mir.r>0.5?1.0-tcR.x:tcR.x, tcR.y);
    vec2 fG=vec2(mir.g>0.5?1.0-tcG.x:tcG.x, tcG.y);
    vec2 fB=vec2(mir.b>0.5?1.0-tcB.x:tcB.x, tcB.y);

    float ca=0.0015+0.004*a;
    vec4 C=texture(samp,uv);
    C.r=texture(samp,fR+vec2( ca,0)).r;
    C.g=texture(samp,fG              ).g;
    C.b=texture(samp,fB+vec2(-ca,0)).b;

    float pulseChrom=0.004*(0.5+0.5*sin(t*3.7+seed));
    C.rgb+=pulseChrom*ua;
    vec3 chromRGB = C.rgb;

    vec4 baseTex = texture(samp, uv);
    vec2 uvN = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    uvN.x *= aspect;
    float r = pingPong(sin(length(uvN) * time_f), 5.0);
    float radiusN = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radiusN, radiusN - 0.25, r);

    vec2 ar = vec2(aspect, 1.0);
    vec3 baseCol = preBlendColor(uv);
    float seg = 4.0 + 2.0 * sin(time_f * 0.33);
    vec2 kUV = reflectUV(uv, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.45 + 0.55 * sin(time_f * 0.42);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * 0.23, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x) q = q.yx;

    float baseZ = 1.82 + 0.18 * pingPong(sin(time_f * 0.2) * (PI * time_f), 5.0);
    float period = log(baseZ) * pingPong(time_f * PI, 5.0);
    float tz = time_f * 0.65;
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + time_f * 0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;
    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);
    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(time_f * 1.3)) * vec2(1.0, 1.0 / aspect);

    float vign = 1.0 - smoothstep(0.75, 1.2, length((tc - m) * ar));
    vign = mix(0.9, 1.15, vign);

    vec3 rC = preBlendColor(u0 + off);
    vec3 gC = preBlendColor(u1);
    vec3 bC = preBlendColor(u2 - off);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + time_f * 1.2));
    ring = ring * pingPong((time_f * PI), 5.0);
    float pulse = 0.5 + 0.5 * sin(time_f * 2.0 + rD * 28.0 + k * 12.0);

    vec3 outCol = kaleidoRGB;
    outCol *= (0.75 + 0.25 * ring) * (0.85 + 0.15 * pulse) * vign;
    vec3 bloom = outCol * outCol * 0.18 + pow(max(outCol - 0.6, 0.0), vec3(2.0)) * 0.12;
    outCol += bloom;

    float mixNeonBase = pingPong(pulse * PI, 5.0) * 0.18;
    vec3 neonBaseMix = mix(baseCol, outCol, 0.65 + 0.35*ua);
    vec3 neonOut = mix(baseTex.rgb, neonBaseMix, mixNeonBase + 0.45);
    neonOut = clamp(neonOut, vec3(0.05), vec3(0.97));

    float glowMix = pingPong(glow * PI, 5.0) * 0.8;
    vec3 neonFinal = mix(baseTex.rgb, neonOut, glowMix);

    float layerMix = clamp(0.35 + 0.4*a + 0.25*ua, 0.0, 1.0);
    vec3 finalRGB = mix(neonFinal, chromRGB, layerMix);

    color = vec4(finalRGB, 1.0);
}
