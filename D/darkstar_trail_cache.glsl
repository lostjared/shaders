#version 330 core
// af_kaleido-cache-acid-star
// Merges spectrum-driven fractal folds with a dynamic, frequency-historical trail.

in vec2 tc;
out vec4 color;

// --- CORE UNIFORMS ---
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

// --- HISTORY CACHE UNIFORMS ---
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

// --- AUDIO SPECTRUM UNIFORMS ---
uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

// --- UTILITIES & MATH ---

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

mat2 rotate_2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.02, 0.35, 0.69)));
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = TAU / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
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

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect, float bass) {
    vec2 p = uv;
    for (int i = 0; i < 3; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * (0.35 + bass * 0.2) + float(i)))) - 0.5 + c;
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

// --- OPTIMIZED SAMPLERS ---

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(index + 1)))).r;
}

// --- CORE GENERATORS ---

vec2 dynamic_trail_transform(vec2 uv, vec2 center, int index, int total_layers, float bass, float treble, float time) {
    float progress = float(index) / float(max(total_layers - 1, 1));
    float shrink_factor = 1.0 + (bass * 1.5); 
    float current_scale = mix(1.0, 1.0 / shrink_factor, progress);
    
    float max_angle = progress * (treble * PI) * sin(time * 0.5);
    mat2 rot = rotate_2d(max_angle);
    
    vec2 point = uv - center;
    point = rot * (point / current_scale);
    
    return mirror_repeat(point + center);
}

vec3 generate_live_frame(vec2 uv, vec2 res, float aspect, vec2 m, float bass, float mid, float treble, float rms, float peak) {
    float void_presence = 1.0 - smoothstep(0.0, 0.15, rms);
    float jam_build = smoothstep(0.05, 0.6, rms);
    
    vec2 mapped_uv = uv * 2.0 - 1.0;
    mapped_uv.x *= aspect;
    
    float r = pingPong(sin(length(mapped_uv) * time_f), 5.0); 
    float radius = sqrt(aspect * aspect + 1.0) + 0.5;
    float glow = smoothstep(radius, radius - (0.5 + bass * 0.3), r);
    vec2 ar = vec2(aspect, 1.0);
    
    float seg = 4.0 + (2.0 + mid * 2.0 * jam_build) * sin(time_f * 0.33);
    vec2 kUV = reflectUV(uv, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    
    float foldZoom = 1.15 + (0.2 * void_presence + bass * jam_build * 0.8) * sin(time_f * (0.42 + jam_build * 0.5));
    
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect, bass);
    kUV = rotateUV(kUV, time_f * (0.23 + bass * 0.15), m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    
    vec2 p = (kUV - m) * ar;
    vec2 q = abs(p);
    if (q.y > q.x) q = q.yx;
    
    float base_val = 1.82 + 0.18 * pingPong(sin(time_f * 0.2) * (PI * time_f), 5.0);
    float period = log(base_val) * pingPong(time_f * PI, 5.0);
    float tz = time_f * (0.65 + bass * 0.3 * jam_build);
    
    float rD = diamondRadius(p) + 1e-6;
    float ang = atan(q.y, q.x) + tz * 0.35 + 0.35 * sin(rD * 18.0 + time_f * 0.6);
    
    float k = fract((log(rD) - tz) / period);
    float rw = exp(k * period);
    
    vec2 pwrap = vec2(cos(ang), sin(ang)) * rw * 0.5;
    vec2 u0 = fract(pwrap / ar + m);
    vec2 u1 = fract((pwrap * 1.045) / ar + m);
    vec2 u2 = fract((pwrap * 0.955) / ar + m);
    
    vec2 dir = normalize(pwrap + 1e-6);
    float chromatic_drift = (0.004 * void_presence * sin(time_f * 0.4)) + (treble * 0.008 * jam_build);
    vec2 off = dir * chromatic_drift * vec2(1.0, 1.0 / aspect);
    
    float vign = 1.0 - smoothstep(0.75, 1.2, length((uv - m) * ar));
    vign = mix(0.9, (1.15 + rms * 0.2), vign);
    
    vec3 rC = tentBlur3(samp, u0 + off, res) * 0.7;
    vec3 gC = tentBlur3(samp, u1, res) * 0.7;
    vec3 bC = tentBlur3(samp, u2 - off, res) * 0.7;
    vec3 kaleidoRGB = vec3(rC.r, gC.g, bC.b);
    
    float ring = smoothstep(0.0, 0.7, sin(log(rD + 1e-3) * 9.5 + time_f * 1.2));
    ring = ring * pingPong((time_f * PI), 5.0) * (1.0 + mid * 0.3 * jam_build);
    
    float pulse = 0.5 + (0.5 + rms * 0.3 * jam_build) * sin(time_f * 2.0 + rD * 28.0 + k * 12.0);
    
    vec3 outCol = clamp(kaleidoRGB * (0.6 + 0.4 * pulse) * vign, 0.0, 1.0);
    vec4 baseTex = texture(samp, uv);
    vec3 finalRGB = mix(baseTex.rgb * 0.8, outCol, pingPong(glow * PI, 5.0) * (0.5 + 0.5 * jam_build));
    
    finalRGB = mix(finalRGB, finalRGB * vec3(0.7, 0.8, 1.2), void_presence);
    finalRGB *= 1.0 + (peak * 1.5 * jam_build) + (void_presence * 0.2);
    
    vec3 eqColor = vec3(1.0 + bass * 0.4, 1.0 - bass * 0.2, 1.0 + clamp(treble, 0.0, 1.0) * 0.4);
    finalRGB = mix(finalRGB, finalRGB * eqColor, peak * jam_build);
    
    return finalRGB;
}

void main() {
    vec2 res = max(iResolution, vec2(1.0));
    float aspect = res.x / res.y;
    vec2 m = (iMouse.z > 0.0) ? (iMouse.xy / res) : vec2(0.5);

    // Fetch live audio directly from the spectrum texture mapping (approximate bands)
    float bass = texture(spectrum0, 0.05).r;
    float mid = texture(spectrum0, 0.25).r;
    float treble = texture(spectrum0, 0.70).r;
    
    float rms = (bass + mid + treble) / 3.0;
    float peak = max(bass, max(mid, treble));

    // 1. GENERATE KALEIDOSCOPIC LIVE FRAME
    vec3 live = generate_live_frame(tc, res, aspect, m, bass, mid, treble, rms, peak);
    
    // 2. CALCULATE AUDIO HISTORICAL TRAIL
    vec3 trail_accum = vec3(0.0);
    float trail_weight = 0.0;

    for (int index = 0; index < SIZE; ++index) {
        float old_bass = sample_history(index, 0.05);
        float old_treble = sample_history(index, 0.70);
        
        vec2 history_uv = dynamic_trail_transform(tc, m, index, SIZE, old_bass, old_treble, time_f);
        vec3 cached = sample_cache(index, history_uv).rgb;
        
        float progress = float(index) / float(max(SIZE - 1, 1));
        float weight = exp(-progress * 3.5); 
        
        vec3 trail_tint = mix(vec3(1.0), palette(time_f * 0.2 + progress + old_bass), progress * 0.8);
        
        trail_accum += (cached * trail_tint) * weight;
        trail_weight += weight;
    }

    vec3 trail = trail_accum / max(trail_weight, 0.001);
    trail *= 0.65;
    
    // 3. COMPOSITE (Screen Blend)
    vec3 result = live + trail - (live * trail);
    
    // Final contrast and pumping
    result = (result - 0.5) * (1.1 + rms * 0.2) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, peak));

    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}