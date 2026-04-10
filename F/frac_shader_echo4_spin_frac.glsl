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

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float pingPong(float x, float length){
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 screenToComplex(vec2 screenPos, vec2 center, float zoom){
    vec2 scale = vec2(zoom * (iResolution.x / iResolution.y), zoom);
    return center + (screenPos - iResolution * 0.5) * scale;
}

const int maxIterations = 300;

float mandelbrotSmooth(vec2 c, out float itCount){
    vec2 z = vec2(0.0);
    float maxI = float(maxIterations);
    float iFloat = 0.0;
    for(int j = 0; j < maxIterations; j++){
        iFloat = float(j);
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        if(dot(z, z) > 4.0){
            float log_zn = log(dot(z, z)) * 0.5;
            float nu = iFloat + 1.0 - log(log_zn / log(2.0)) / log(2.0);
            itCount = iFloat;
            return clamp(nu / maxI, 0.0, 1.0);
        }
    }
    itCount = maxI;
    return 1.0;
}

vec2 interestingCenters(int index){
    vec2 centers[5];
    centers[0] = vec2(-0.743643887037151, 0.13182590420533);
    centers[1] = vec2(-0.745428, 0.113009);
    centers[2] = vec2(-0.7453, 0.1127);
    centers[3] = vec2(-0.7435, 0.1318);
    centers[4] = vec2(-0.743644786, 0.1318252536);
    return centers[index % 5];
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect){
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect, float spin){
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x) + spin;
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

void main(void){
    vec2 res = iResolution;
    vec2 uv = tc;
    vec2 ar = vec2(res.x / res.y, 1.0);

    float baseTime = time_f + iTime;
    float t = baseTime + float(iFrame) * 0.002;

    float sr = clamp(iSampleRate / 48000.0, 0.25, 4.0);
    float deltaFactor = clamp(iTimeDelta * 60.0, 0.2, 3.0);
    float aMix = clamp(amp * 0.7 + uamp * 0.3, 0.0, 20.0);

    vec2 m = (iMouse.z > 0.5 ? (iMouse.xy / res) : vec2(0.5));
    vec2 clickUV = (iMouseClick.x > 0.0 || iMouseClick.y > 0.0) ? (iMouseClick / res) : m;

    float datePhase = dot(iDate.xy, vec2(0.01, 0.003));
    float frPhase = clamp(iFrameRate / 60.0, 0.4, 2.0);
    float chBeat = 0.0;
    for(int i = 0; i < 4; i++){
        chBeat += sin(iChannelTime[i] * 0.35 + float(i));
    }
    chBeat *= 0.25;

    float zoomCycleSpeed = 0.035 * deltaFactor * frPhase;
    float zoomIntensity = 14.0 + aMix * 0.25;
    float zoomPing = pingPong(baseTime * zoomCycleSpeed * (0.6 + 0.4 * sr), 1.0);
    float zoom = exp(-zoomPing * zoomIntensity);

    int cycleIndex = int(floor(baseTime * 0.08 + chBeat * 2.0));
    vec2 center = interestingCenters(cycleIndex);

    float seg = 5.0 + 3.0 * sin(t * 0.25 + chBeat);
    float kaleidoSpin = t * 0.45 + aMix * 0.03;
    vec2 kUV = reflectUV(uv, seg, m, ar.x, kaleidoSpin);

    float zoomFold = 1.3 + 0.4 * sin(t * 0.3 + sr) + 0.2 * chBeat;
    kUV = fractalFold(kUV, zoomFold, t, m, ar.x);

    float radial = length((kUV - m) * ar);
    float globalSpin = t * 0.6 + 0.3 * chBeat;
    kUV = rotateUV(kUV, globalSpin + radial * 3.5, m, ar.x);

    vec2 frag = vec2(uv.x * res.x, uv.y * res.y);
    vec2 fragWarp = frag
        + (kUV - uv) * res.y * (0.35 + 0.25 * aMix / 20.0)
        + (clickUV - m) * res * 0.6 * exp(-radial * 4.0);

    vec2 cplx = screenToComplex(fragWarp, center, zoom);

    float spin = t * 0.18 + 0.25 * chBeat;
    float cs = cos(spin), sn = sin(spin);
    vec2 cRel = cplx - center;
    cRel = vec2(cRel.x * cs - cRel.y * sn, cRel.x * sn + cRel.y * cs);
    cplx = cRel + center;

    float iterCount;
    float nu = mandelbrotSmooth(cplx, iterCount);

    vec3 neon = neonPalette(t + nu * 6.0 + datePhase);
    float glow = smoothstep(0.0, 1.0, pow(nu, 0.9));
    vec3 fractCol = mix(neon * 0.4, neon * 1.8, glow);

    float ring = smoothstep(0.2, 0.0, abs(nu - 0.5));
    fractCol *= 0.8 + 0.6 * ring;

    fractCol *= 0.7 + 0.6 * aMix / 20.0;

    vec2 dtx = dFdx(uv);
    vec2 dty = dFdy(uv);
    vec4 baseTex = textureGrad(samp, uv, dtx, dty);
    vec3 base = baseTex.rgb;

    vec4 s2 = textureGrad(samp, uv * 0.5, dtx * 0.5, dty * 0.5);
    vec4 s3 = textureGrad(samp, uv * 0.25 + 0.03 * vec2(sin(t), cos(t)), dtx * 0.25, dty * 0.25);
    vec4 s4 = textureGrad(samp, uv * 0.125 + 0.09 * (kUV - m) * ar, dtx * 0.125, dty * 0.125);
    vec3 multi = (base + s2.rgb + s3.rgb + s4.rgb) * 0.25;

    float multiMix = 0.25 + 0.35 * (1.0 - nu);
    vec3 fractEnhanced = fractCol;
    fractEnhanced *= 0.9 + 0.4 * sin(t * 0.4 + nu * 12.0 + chBeat);

    vec3 pattern = mix(fractEnhanced, multi, multiMix);

    float PATTERN_ALPHA = 0.88;
    float BASE_ALPHA = 0.20;

    vec3 combined = base * BASE_ALPHA + pattern * PATTERN_ALPHA;

    float vignette = 1.0 - 0.45 * radial * radial;
    combined *= clamp(vignette + 0.2, 0.0, 1.3);

    vec3 bloom = combined * combined * 0.35 + pow(max(combined - 0.55, 0.0), vec3(3.0)) * 0.25;
    combined += bloom;

    combined = pow(max(combined, 0.0), vec3(0.9));
    combined = clamp(combined, vec3(0.0), vec3(1.0));

    color = vec4(combined, 1.0);
}
