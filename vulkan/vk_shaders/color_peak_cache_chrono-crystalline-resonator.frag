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

// chrono_crystalline_resonator
// Fuses topological metallic displacement with aggressive historical ring-buffer refraction.
// Uses the prominent right-click test to shatter the geometry through recursive normal-mapping.
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

// Procedural Palette
vec3 acid(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.3, 0.2, 0.2);
    return a + b * cos(TAU * (c * t + d));
}

vec3 spectral(float x) {
    return 0.55 + 0.45 * cos(TAU * (x + vec3(0.00, 0.31, 0.67)));
}

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

// Fractured Topological Heightmap
float heightField(vec2 p, vec2 effectOrigin, float bass, float mid) {
    float t = time_f;
    float nave = fbm(p * 3.5 + vec2(t * 0.1, -t * 0.3));
    
    vec2 polarUV = p - effectOrigin;
    float r = length(polarUV);
    float theta = atan(polarUV.y, polarUV.x);
    
    // Geometric structural base
    float archX = sqrt(p.x * p.x + 0.01);
    float arches = cos(archX * (10.0 + mid * 8.0) - p.y * 5.0 + nave * 4.0);
    
    // Audio-reactive crystalline fracturing
    float spiralArms = 5.0 + floor(amp_high * 6.0);
    float spiralPhase = theta * spiralArms - r * 20.0 - t * 4.0;
    float crystalline = abs(sin(spiralPhase)) * exp(-r * (1.5 - bass));
    
    // Rippling interference waves
    float wave = sin(r * (25.0 + bass * 20.0) - t * 8.0);

    return nave * 0.5 + arches * 0.2 - crystalline * 0.3 + wave * 0.15;
}

vec3 normalAt(vec2 p, float e, vec2 origin, float bass, float mid) {
    float h = heightField(p, origin, bass, mid);
    vec2 g = vec2(heightField(p + vec2(e, 0), origin, bass, mid) - h, 
                  heightField(p + vec2(0, e), origin, bass, mid) - h) / e;
    return normalize(vec3(-g * 0.35, 1.0));
}

vec3 metalLight(vec3 base, vec3 n, vec2 p, float rough) {
    vec3 v = normalize(vec3(-p * 0.15, 2.0));
    vec3 l0 = normalize(vec3(-0.6, 0.7, 0.8));
    vec3 l1 = normalize(vec3(0.8, -0.2, 0.6));
    float nv = max(dot(n, v), 0.0);
    
    vec3 f0 = mix(vec3(0.6), base, 0.8);
    vec3 fres = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), mix(200.0, 30.0, rough));
    float s1 = pow(max(dot(n, normalize(v + l1)), 0.0), mix(120.0, 20.0, rough));
    
    vec3 r = reflect(-v, n);
    vec3 env = mix(vec3(0.02, 0.05, 0.08), spectral(r.x * 0.2 + r.y * 0.15 + time_f * 0.03), 0.6 + 0.3 * r.z);
                   
    vec3 direct = vec3(1.0, 0.9, 0.8) * s0 * 2.5 + vec3(0.3, 0.6, 1.0) * s1 * 1.8;
    return base * (0.1 + 0.2 * max(dot(n, l0), 0.0)) + env * fres * 1.5 + direct * fres;
}

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
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air    = texture(spectrum0, 0.80).r;

    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = iMouse.xy / iResolution.xy;

    vec2 effectOrigin = (iMouse.z > 0.0) ? (mouseUV - 0.5) * vec2(aspect, 1.0) : vec2(0.0);

    // Geometry Generation
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    vec3 n = normalAt(p, e, effectOrigin, bass, mid);
    float h = heightField(p, effectOrigin, bass, mid);
    
    // Live Video Input with Chromatic Dispersion mapped to the structural normals
    float dispersion = 0.008 + amp_high * 0.015;
    vec2 flow = n.xy * (0.04 + amp_low * 0.05);
    vec2 uv = repeatMirror(tc + flow);
    
    vec3 tex = vec3(
        texture(samp, repeatMirror(uv + n.xy * dispersion)).r, 
        texture(samp, uv).g,
        texture(samp, repeatMirror(uv - n.xy * dispersion)).b
    );

    // Initial Shading: Mix structural metallic properties with live input and acid palette
    float lum = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 acidBase = acid(h * 0.7 + time_f * 0.2 + bass);
    vec3 alloy = mix(vec3(lum) * vec3(0.85, 0.95, 1.0), acidBase * tex, 0.5);
    vec3 lit = metalLight(alloy, n, p, 0.05 + 0.2 * fbm(p * 10.0));
    
    vec3 current_col = lit * (0.8 + amp_smooth * 0.3);

    // Aggressive Historical Ring Buffer Refraction
    vec3 accum = current_col;
    float accWeight = 1.0;

    vec2 feedbackCenter = (iMouse.z > 0.0) ? mouseUV : vec2(0.5);
    
    vec3 userHueShift = vec3(0.0);
    float userZoomShift = 0.0;
    float normalRefraction = 0.05; // Base refraction amount
    
    if (iMouse.w > 0.0) {
        userHueShift = vec3((mouseUV.x - 0.5) * 8.0, -(mouseUV.x - 0.5) * 6.0, (mouseUV.x - 0.5) * 5.0);
        userZoomShift = (0.5 - mouseUV.y) * 1.6;
        normalRefraction += abs(mouseUV.x - 0.5) * 0.4; // Extreme right-click drastically increases 3D refraction
    }

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);
        float h_bass   = sampleSpectrumHistory(i, 0.03);
        float h_mid    = sampleSpectrumHistory(i, 0.22);
        float h_treble = sampleSpectrumHistory(i, 0.58);
        
        float rawZoom = 0.95 + 0.03 * sin(time_f * 0.5) - (h_bass * 0.15) + userZoomShift; 
        float zoom = pow(max(rawZoom, 0.01), gen);
        
        float rot = (0.03 * sin(time_f * 0.3) + (h_treble * 0.2)) * gen;
        float cs = cos(rot), sn = sin(rot);

        // Calculate standard feedback coordinates
        vec2 centered = tc - feedbackCenter;
        centered *= zoom;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
        
        // Critical modification: The history buffer is physically warped by the current fragment's 3D normal
        vec2 fbUV = centered + feedbackCenter + (n.xy * normalRefraction * gen * (1.0 + h_mid));

        vec4 cached = sampleCache(i, fbUV);

        float shift = gen * 0.05;
        cached.r *= 1.0 + shift + (h_mid * 0.25) + (userHueShift.r * gen * 0.3);
        cached.g *= 1.0 - shift * 0.8 - (h_bass * 0.15) + (userHueShift.g * gen * 0.3);
        cached.b *= 1.0 + shift * 0.4 + (h_treble * 0.3) + (userHueShift.b * gen * 0.3);

        float w = pow(0.78, gen); 
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // Hard glitch thresholds and tonemapping
    accum = (accum - 0.5) * 1.2 + 0.5; 
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.85, 1.0, amp_peak));
    
    color = vec4(aces(accum), texture(samp, uv).a);
}