#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

const float PI = 3.1415926535897932384626433832795;

// Helper for neon color palette
vec3 getNeon(float t) {
    // Standard cosine gradient for neon colors (Pink, Blue, Cyan, Purple)
    return 0.5 + 0.5 * cos(6.28318 * (vec3(1.0, 1.0, 1.0) * t + vec3(0.0, 0.33, 0.67)));
}

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
    for (int i = 0; i < 3; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

// Fixed Blur: Using standard texture() to leverage Mipmaps for anti-aliasing
vec3 smoothSample(sampler2D img, vec2 uv) {
    return texture(img, uv).rgb;
}

vec3 preBlendColor(vec2 uv) {
    vec3 tex = smoothSample(samp, uv);
    // Convert to neon spectrum based on brightness and time
    float brightness = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 neon = getNeon(brightness + time_f * 0.5);
    return mix(tex, neon, 0.6) * 1.2; 
}

float diamondRadius(vec2 p) {
    p = sin(abs(p));
    return max(p.x, p.y);
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + c;
}

void main(void) {
    vec2 xuv = 1.0 - abs(1.0 - 2.0 * tc);
    vec4 baseTex = texture(samp, xuv);
    
    vec2 uv = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    
    float r = pingPong(sin(length(uv) * time_f), 5.0); 
    float radius = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radius, radius - 0.5, r);
    
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
    
    float base = 1.82 + 0.18 * pingPong(sin(time_f * 0.2) * (PI * time_f), 5.0);
    float period = log(base) * pingPong(time_f * PI, 5.0);
    float tz = time_f * 0.65;
    
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + time_f * 0.6);
    
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw * 0.5;
    
    // Chromatic aberration / Neon offsets
    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.02) / ar + m);
    vec2 u2 = fract((pwrap * 0.98) / ar + m);
    
    vec3 rC = preBlendColor(u0);
    vec3 gC = preBlendColor(u1);
    vec3 bC = preBlendColor(u2);
    
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);
    
    // STROBE CALCULATION
    // High frequency strobe synced with a pulse
    float strobe = 0.8 + 0.2 * sin(time_f * 25.0); 
    float pulse = 0.5 + 0.5 * sin(time_f * 4.0 + rD * 10.0);
    
    vec3 outCol = kaleidoRGB * strobe * (0.7 + 0.5 * pulse);
    
    // Boost the "Neon" factor
    outCol = pow(outCol, vec3(0.8)); // Gamma pull for punchier colors
    outCol *= 1.3; // Exposure boost
    
    float vign = 1.0 - smoothstep(0.7, 1.5, length((tc - m) * ar));
    outCol *= vign;
    
    vec3 finalRGB = mix(baseTex.rgb * 0.3, outCol, 0.8);
    
    color = vec4(finalRGB, 1.0);
}