#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

const float PI = 3.1415926535897932384626433832795;

// --- FLUID NOISE (From Shader 1) ---

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Smooth FBM for Liquid Effect
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// --- FRACTAL FUNCTIONS ---

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
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
    float ph = fract(t * 0.08);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    float a = step(ph, 0.33);
    float b = step(0.33, ph) * step(ph, 0.66);
    float c = step(0.66, ph);
    return normalize(a * k1 + b * k2 + c * k3) * 1.05;
}

vec3 softTone(vec3 c) {
    c = pow(max(c, 0.1), vec3(0.95));
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, 0.9);
    return clamp(c, 0.1, 1.0);
}

vec3 tentBlur3(sampler2D img, vec2 uv, vec2 res) {
    vec2 ts = 1.0 / res;
    vec3 s = texture(img, uv).rgb * 4.0;
    s += texture(img, uv + ts * vec2(1.0, 1.0)).rgb;
    s += texture(img, uv + ts * vec2(-1.0, -1.0)).rgb;
    s += texture(img, uv + ts * vec2(-1.0, 1.0)).rgb;
    s += texture(img, uv + ts * vec2(1.0, -1.0)).rgb;
    return s / 8.0;
}

vec3 preBlendColor(vec2 uv) {
    vec3 tex = tentBlur3(samp, uv, iResolution);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    vec3 neon = neonPalette(time_f + r * 1.3);
    float neonAmt = smoothstep(0.1, 0.8, r);
    neonAmt = 0.3 + 0.4 * (1.0 - neonAmt);
    vec3 grad = mix(tex, neon, neonAmt);
    grad = mix(grad, tex, 0.2);
    grad = max(grad, neon * 0.2);
    grad = softTone(grad);
    return grad;
}

float diamondRadius(vec2 p) {
    p = sin(abs(p));
    return max(p.x, p.y);
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;
    p.x /= aspect;
    return p + c;
}

void main(void) {
    vec4 baseTex = texture(samp, tc);

    vec2 uv = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 ar = vec2(aspect, 1.0);

    // --- LIQUID INJECTION ---
    // Generate flow vectors based on screen position and time
    float flow1 = fbm(uv * 1.5 + time_f * 0.2);
    float flow2 = fbm(uv * 2.0 - time_f * 0.15);
    vec2 flow = vec2(cos(flow1 * 5.0), sin(flow2 * 5.0)) * 0.05; // 0.05 = subtle liquid strength

    // Apply flow to the initial coordinates BEFORE they enter the fractal loop
    vec2 warpedUV = tc + flow;

    // --- FRACTAL GENERATION ---
    float seg = 4.0 + 2.0 * sin(time_f * 0.33);

    // Pass warpedUV into the folding functions
    vec2 kUV = reflectUV(warpedUV, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    // Liquid Zoom: Oscillate zoom slightly with the noise
    float foldZoom = 1.45 + 0.55 * sin(time_f * 0.42 + flow1);

    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * 0.23, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x)
        q = q.yx;

    // Log Polar Tunnel with Fluid Distortion
    float base = 1.82 + 0.18 * pingPong(sin(time_f * 0.2) * (PI * time_f), 5.0);
    float period = log(base) * pingPong(time_f * PI, 5.0);
    float tz = time_f * 0.65;
    float rD = diamondRadius(p) + 1e-6;

    // Distort angle with flow
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + time_f * 0.6 + flow2 * 3.0);

    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);

    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw;

    // --- SAMPLING ---
    vec2 u0 = fract(pwrap / ar + m);
    // Use flow for organic chromatic aberration
    float spread = 1.045 + (0.02 * flow1);
    vec2 u1 = fract((pwrap * spread) / ar + m);
    vec2 u2 = fract((pwrap * (1.0 / spread)) / ar + m);

    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * (0.0015 + 0.001 * sin(time_f * 1.3)) * vec2(1.0, 1.0 / aspect);

    vec3 rC = preBlendColor(u0 + off);
    vec3 gC = preBlendColor(u1);
    vec3 bC = preBlendColor(u2 - off);
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);

    // --- COMPOSITING ---

    // Mask Logic - FLOORED to prevent black
    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + time_f * 1.2));
    ring = 0.3 + 0.7 * ring;

    float pulse = 0.5 + 0.5 * sin(time_f * 2.0 + rD * 28.0 + k * 12.0);
    pulse = 0.4 + 0.6 * pulse;

    vec3 effectColor = kaleidoRGB;
    effectColor *= (ring * pulse);

    vec3 fillPalette = neonPalette(length(p) + time_f) * 0.15;
    effectColor = max(effectColor, fillPalette);

    vec3 bloom = effectColor * effectColor * 0.18 + pow(max(effectColor - 0.6, 0.0), vec3(2.0)) * 0.12;
    effectColor += bloom * 1.2;

    // Additive Blend
    // Modulate intensity with flow for a "shimmering" look
    float intensity = 0.6 + 0.2 * flow1 + 0.4 * pingPong(time_f, 2.0);
    vec3 finalRGB = baseTex.rgb + (effectColor * intensity);

    color = vec4(clamp(finalRGB, 0.0, 1.0), baseTex.a);
}