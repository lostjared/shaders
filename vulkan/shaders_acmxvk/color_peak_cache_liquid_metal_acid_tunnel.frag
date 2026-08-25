#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// liquid_metal_acid_tunnel
// Combines pseudo-3D heightfield raymarching with 8-frame historical FFT feedback
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

// Live feed and cache layers
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

// Historical FFT data (0 is now, 7 is oldest)
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

// Uniforms









const float TAU = 6.28318530718;

// Math & Noise Utilities
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + 1.0), f.x), f.y);
}

float fbm(vec2 p) {
    float f = 0.0, a = 0.5;
    mat2 m = mat2(0.80, -0.60, 0.60, 0.80);
    for (int i = 0; i < 5; ++i) {
        f += a * noise21(p);
        p = m * p * 2.03 + 1.7;
        a *= 0.5;
    }
    return f;
}

vec2 repeatMirror(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

// Color Utilities
vec3 spectral(float x) {
    return 0.55 + 0.45 * cos(TAU * (x + vec3(0.00, 0.31, 0.67)));
}

vec3 acid(float t, float hueOffset) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.3, 0.2, 0.2) + vec3(hueOffset, hueOffset * 1.2, hueOffset * 0.8);
    return a + b * cos(TAU * (c * t + d));
}

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

// 3D Topology driven by 2D Spirals and Audio
float heightField(vec2 p, vec2 effectOrigin, float bass, float mid) {
    float t = time_f;
    float nave = fbm(p * 2.8 + vec2(0.0, -t * 0.22));
    
    vec2 polarUV = p - effectOrigin;
    float r = length(polarUV);
    float theta = atan(polarUV.y, polarUV.x);
    
    // Original cathedral structural elements
    float archX = sqrt(p.x * p.x + 0.0036);
    float arches = cos(archX * (13.0 + mid * 5.0) - p.y * 4.0 + nave * 3.0);
    
    // Acid spirals injected physically into the heightmap
    float spiralArms = 3.0 + floor(amp_high * 4.0);
    float spiralTwist = 15.0 - bass * 8.0;
    float spiralPhase = theta * spiralArms - r * spiralTwist - t * 5.0;
    float spiralDrops = pow(max(sin(spiralPhase), 0.0), 3.0) * exp(-r * (2.0 - mid));
    
    // Rippling interference waves
    float wave = sin(r * (20.0 + bass * 15.0) - t * 5.0);

    return nave * 0.4 + arches * 0.15 + spiralDrops * 0.25 + wave * 0.1;
}

// Normal generation with dynamic context
vec3 normalAt(vec2 p, float e, vec2 origin, float bass, float mid) {
    float h = heightField(p, origin, bass, mid);
    vec2 g = vec2(heightField(p + vec2(e, 0), origin, bass, mid) - h, 
                  heightField(p + vec2(0, e), origin, bass, mid) - h) / e;
    return normalize(vec3(-g * 0.22, 1.0));
}

// Physically based metallic shading with environmental spectral reflections
vec3 metalLight(vec3 base, vec3 n, vec2 p, float rough) {
    vec3 v = normalize(vec3(-p * 0.12, 1.8));
    vec3 l0 = normalize(vec3(-0.55, 0.65, 0.80));
    vec3 l1 = normalize(vec3(0.72, -0.18, 0.67));
    float nv = max(dot(n, v), 0.0);
    
    vec3 f0 = mix(vec3(0.55), base, 0.72);
    vec3 fres = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), mix(180.0, 22.0, rough));
    float s1 = pow(max(dot(n, normalize(v + l1)), 0.0), mix(110.0, 15.0, rough));
    
    vec3 r = reflect(-v, n);
    vec3 env = mix(vec3(0.025, 0.04, 0.07), spectral(r.x * 0.18 + r.y * 0.13 + time_f * 0.025),
                   0.62 + 0.25 * r.z);
                   
    vec3 direct = vec3(1.0, 0.88, 0.72) * s0 * 2.4 + vec3(0.28, 0.58, 1.0) * s1 * 1.5;
    return base * (0.08 + 0.18 * max(dot(n, l0), 0.0)) + env * fres * 1.25 + direct * fres;
}

// Ringbuffer Helpers
vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (idx == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (idx == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (idx == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (idx == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (idx == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (idx == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

float sampleSpectrumHistory(int idx, float freq) {
    if (idx == 0) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(1)))).r; 
    if (idx == 1) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(2)))).r; 
    if (idx == 2) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (idx == 3) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (idx == 4) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (idx == 5) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(7)))).r;               
}

void main(void) {
    // 1. Setup Audio & Interaction
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air    = texture(spectrum0, 0.80).r;

    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = iMouse.xy / iResolution.xy;

    float globalHueShift = (iMouse.w > 0.0) ? (mouseUV.x - 0.5) * 3.0 : 0.0;
    vec2 effectOrigin = (iMouse.z > 0.0) ? (mouseUV - 0.5) * vec2(aspect, 1.0) : vec2(0.0);

    // 2. Generate 3D Surface
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    vec3 n = normalAt(p, e, effectOrigin, bass, mid);
    float h = heightField(p, effectOrigin, bass, mid);
    
    // Flow texture coordinates along the computed normals
    vec2 flow = n.xy * (0.032 + amp_low * 0.04);
    vec2 uv = repeatMirror(tc + flow);
    
    // Chromatic dispersion for the live feed fetching
    float dispersion = 0.005 + amp_high * 0.01;
    vec3 tex = vec3(
        texture(samp, repeatMirror(uv + n.xy * dispersion)).r, 
        texture(samp, uv).g,
        texture(samp, repeatMirror(uv - n.xy * dispersion)).b
    );

    // 3. Shading & Coloring
    float lum = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 acidBase = acid(h * 0.5 + time_f * 0.1 + bass, globalHueShift);
    
    // Blend the raw texture luminance into the acid palette to create a metallic alloy
    vec3 alloy = mix(vec3(lum) * vec3(0.82, 0.90, 1.0), acidBase * tex, 0.45);
    
    vec3 lit = metalLight(alloy, n, p, 0.1 + 0.15 * fbm(p * 5.0));
    
    // Highlight the crests of the waves and spirals
    float crest = pow(max(sin(h * 15.0 - time_f * 3.0), 0.0), 6.0);
    lit += spectral(h * 0.6 + time_f * 0.05) * crest * (0.5 + amp_peak);
    
    vec3 current_col = lit * (0.9 + amp_smooth * 0.2);

    // 4. Ringbuffer Recursion (Tunneling the 3D surface)
    vec3 accum = current_col;
    float accWeight = 1.0;

    vec2 feedbackCenter = (iMouse.z > 0.0) ? mouseUV + (n.xy * 0.1) : vec2(0.5) + (n.xy * 0.5);

    vec3 userHueShift = vec3(0.0);
    float userZoomShift = 0.0;
    if (iMouse.w > 0.0) {
        userHueShift = vec3((mouseUV.x - 0.5) * 8.0, -(mouseUV.x - 0.5) * 6.0, (mouseUV.x - 0.5) * 5.0);
        userZoomShift = (0.5 - mouseUV.y) * 1.6;
    }

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);
        float h_bass   = sampleSpectrumHistory(i, 0.03);
        float h_mid    = sampleSpectrumHistory(i, 0.22);
        float h_treble = sampleSpectrumHistory(i, 0.58);
        
        float rawZoom = 0.96 + 0.02 * sin(time_f * 0.4) - (h_bass * 0.1) + userZoomShift; 
        float zoom = pow(max(rawZoom, 0.01), gen);
        
        float rot = (0.02 * sin(time_f * 0.2) + (h_treble * 0.1)) * gen;
        float cs = cos(rot), sn = sin(rot);

        vec2 centered = tc - feedbackCenter;
        centered *= zoom;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
        vec2 fbUV = centered + feedbackCenter;

        vec4 cached = sampleCache(i, fbUV);

        // Mutate colors through the feedback generations
        float shift = gen * 0.06;
        cached.r *= 1.0 + shift + (h_mid * 0.2) + (userHueShift.r * gen * 0.2);
        cached.g *= 1.0 - shift * 0.5 - (h_bass * 0.1) + (userHueShift.g * gen * 0.2);
        cached.b *= 1.0 + shift * 0.3 + (h_treble * 0.2) + (userHueShift.b * gen * 0.2);

        float w = pow(0.75, gen); 
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // 5. Final Tonemapping and Glitch Operations
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.9, 1.0, amp_peak));
    
    color = vec4(aces(accum), texture(samp, uv).a);
}