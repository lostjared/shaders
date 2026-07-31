#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float PI = 3.1415926535897932384626433832795;

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
        p = abs((p - c) * (zoom + 0.15 * sin(t * (0.35 + amp_low * 0.2) + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
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
    return tex * 0.7; 
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
    vec2 xuv = tc;
    vec4 baseTex = texture(samp, xuv);
    vec2 uv = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    
    // Dark Star States
    // void_presence: 1.0 when quiet, 0.0 when loud
    float void_presence = 1.0 - smoothstep(0.0, 0.15, amp_smooth);
    // jam_build: 0.0 when quiet, scales up to 1.0 as the band returns
    float jam_build = smoothstep(0.05, 0.6, amp_smooth);
    
    float r = pingPong(sin(length(uv) * time_f), 5.0); 
    float radius = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radius, radius - (0.5 + amp_low * 0.3), r);
    
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 ar = vec2(aspect, 1.0);
    
    vec3 baseCol = preBlendColor(tc); 
    
    // Geometry remains active but untethered during the void
    float seg = 4.0 + (2.0 + amp_mid * 2.0 * jam_build) * sin(time_f * 0.33);
    vec2 kUV = reflectUV(tc, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    
    // Let the fold zoom breathe deeply in the silence, but scale aggressively in the jam
    float foldZoom = 1.15 + (0.2 * void_presence + amp_low * jam_build * 0.8) * sin(time_f * (0.42 + jam_build * 0.5));
    
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    kUV = rotateUV(kUV, time_f * (0.23 + amp_low * 0.15), m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    
    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x) q = q.yx;
    
    float base = 1.82 + 0.18 * pingPong(sin(time_f * 0.2) * (PI * time_f), 5.0);
    float period = log(base) * pingPong(time_f * PI, 5.0);
    float tz = time_f * (0.65 + amp_low * 0.3 * jam_build);
    
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + time_f * 0.6);
    
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw * 0.5;
    
    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);
    
    vec2 dir = normalize(pwrap + 1e-6);
    
    // Chromatic aberration drifts slowly in the void, but snaps tight and aggressive in the jam
    float chromatic_drift = (0.004 * void_presence * sin(time_f * 0.4)) + (amp_high * 0.008 * jam_build);
    vec2 off = dir * chromatic_drift * vec2(1.0, 1.0 / aspect);
    
    float vign = 1.0 - smoothstep(0.75, 1.2, length((tc - m) * ar));
    vign = mix(0.9, (1.15 + amp_smooth * 0.2), vign);
    
    vec3 rC = preBlendColor(u0 + off);
    vec3 gC = preBlendColor(u1);
    vec3 bC = preBlendColor(u2 - off);
    
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);
    
    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + time_f * 1.2));
    ring = ring * pingPong((time_f * PI), 5.0) * (1.0 + amp_mid * 0.3 * jam_build);
    
    float pulse = 0.5 + (0.5 + amp_rms * 0.3 * jam_build) * sin(time_f * 2.0 + rD * 28.0 + k * 12.0);
    
    vec3 outCol = kaleidoRGB;
    outCol *= (0.6 + 0.4 * pulse); 
    outCol *= vign;
    outCol = clamp(outCol, vec3(0.0), vec3(1.0));
    
    // The final mix uses jam_build so the glow effect increases as the volume floor rises
    vec3 finalRGB = mix(baseTex.rgb * 0.8, outCol, pingPong(glow * PI, 5.0) * (0.5 + 0.5 * jam_build));
    
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    
    // --- Audio Reactivity: Dark Star Build Up ---
    
    // 1. In the void, push the colors toward a darker, cooler spectrum
    finalRGB = mix(finalRGB, finalRGB * vec3(0.7, 0.8, 1.2), void_presence);
    
    // 2. As the jam returns, multiply the intensity by the peaks, gated by the build variable
    finalRGB *= 1.0 + (_ab * 1.5 * jam_build) + (void_presence * 0.2);
    
    // 3. Final EQ coloration, strictly tied to the jam state so it doesn't fire off randomly in the quiet section
    vec3 eqColor = vec3(1.0 + _abass * 0.4, 1.0 - _abass * 0.2, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.4);
    finalRGB = mix(finalRGB, finalRGB * eqColor, _ab * jam_build);
    
    color = vec4(finalRGB, baseTex.a);
}