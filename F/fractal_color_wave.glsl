#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

const float PI = 3.1415926535897932384626433832795;

// --- Helper Functions ---

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
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
    // Low iterations (3) for large shapes
    for (int i = 0; i < 3; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + c;
}

float diamondRadius(vec2 p) {
    p = sin(abs(p));
    return max(p.x, p.y);
}

// --- Texture & Rainbow Logic ---

vec3 getRainbowTexture(vec2 uv) {
    // 1. Rainbow Spiral Logic
    vec2 centered = uv * 2.0 - 1.0;
    float wave = sin(centered.x * 10.0 + time_f * 2.0) * 0.1;
    float angle = atan(centered.y + wave, centered.x) + time_f * 2.0;
    vec3 rain = rainbow(angle / (2.0 * PI));
    
    // 2. Sample Texture
    vec3 tex = texture(samp, uv).rgb;
    
    // 3. Blend Rainbow WITH Texture inside the shards (50/50)
    return mix(tex, rain, 0.5);
}

void main(void) {
    // --- 1. Get the Original Background ---
    vec4 background = texture(samp, tc);

    // --- 2. Calculate Fractal Geometry ---
    vec2 uv = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 ar = vec2(aspect, 1.0);
    
    float seg = 4.0 + 2.0 * sin(time_f * 0.33);
    vec2 kUV = reflectUV(tc, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    
    float foldZoom = 1.15 + 0.15 * sin(time_f * 0.42);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * 0.23, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    
    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x) q = q.yx;
    
    float tz = time_f * 0.65;
    float rD = diamondRadius(p) + 1e-6;
    float base = 1.82; 
    float period = log(base);
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + time_f * 0.6);
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw * 0.5;
    
    vec2 dir = normalize(pwrap + 1e-6);
    vec2 off = dir * 0.002 * vec2(1.0, 1.0 / aspect);
    
    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);
    
    vec3 rC = getRainbowTexture(u0 + off);
    vec3 gC = getRainbowTexture(u1);
    vec3 bC = getRainbowTexture(u2 - off);
    
    vec3 fractalCol = vec3(rC.r, gC.g, bC.b);
    
    // Vignette & Pulse
    float vign = 1.0 - smoothstep(0.75, 1.2, length((tc - m) * ar));
    vign = mix(0.9, 1.15, vign);
    float pulse = 0.75 + 0.25 * sin(time_f * 2.0);
    
    fractalCol *= vign * pulse;
    fractalCol = clamp(fractalCol, 0.0, 1.0);

    // --- 3. Final Blend ---
    // Mix the original background with the fractal overlay.
    // 0.0 = Pure Background, 1.0 = Pure Fractal
    // 0.6 = A nice blend where you see the fractal strongly but the image persists.
    vec3 finalRGB = mix(background.rgb, fractalCol, 0.6);
    
    color = vec4(finalRGB, background.a);
}