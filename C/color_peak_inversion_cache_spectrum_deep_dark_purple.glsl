#version 330 core
// ant_light_color_acid_ripple_spiral_ringbuffer
// Audio-reactive spirals, rippling interference, and an 8-frame recursive feedback tunnel
// Left Click: Direct Feedback Center Control
// Right Click: Zoom Control
// Palette: Deep Dark Purple Energy

in vec2 tc;
out vec4 color;

// Live feed and cache layers
uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

// Historical FFT data (0 is now, 7 is oldest)
uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

// Uniforms
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;

// Procedural Palette biased strictly for Deep Dark Purple
vec3 acid(float t) {
    vec3 a = vec3(0.2, 0.02, 0.4); // Very dark violet base
    vec3 b = vec3(0.15, 0.02, 0.3); // Low amplitude to keep it dark
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.5, 0.0, 0.8);  // Phase shifted to pure indigo/purple
    return a + b * cos(TAU * (c * t + d));
}

// Helper to fetch history frames
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

// Helper to fetch historical FFT data matching the cache depth
float sampleSpectrumHistory(int idx, float freq) {
    if (idx == 0) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(1)))).r; 
    if (idx == 1) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(2)))).r; 
    if (idx == 2) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (idx == 3) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (idx == 4) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (idx == 5) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(7)))).r;               
}

void main() {
    // 1. Extract Current Audio Data (Live Frame)
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air    = texture(spectrum0, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = iMouse.xy / iResolution.xy;

    // 2. Base Interference & Glitch Distortion (Current Frame)
    vec2 effectOrigin = vec2(0.0);
    
    vec2 src1 = effectOrigin + vec2(sin(time_f * 0.3) * 0.2, cos(time_f * 0.4) * 0.15);
    vec2 src2 = effectOrigin + vec2(-sin(time_f * 0.5) * 0.15, sin(time_f * 0.3) * 0.2);
    vec2 src3 = effectOrigin + vec2(cos(time_f * 0.2) * 0.1, -cos(time_f * 0.6) * 0.1);

    float r1 = length(uv - src1);
    float r2 = length(uv - src2);
    float r3 = length(uv - src3);

    float wave1 = sin(r1 * (20.0 + bass * 15.0) - time_f * 5.0);
    float wave2 = sin(r2 * (18.0 + mid * 12.0) - time_f * 4.0);
    float wave3 = sin(r3 * (22.0 + treble * 10.0) - time_f * 6.0);

    float combined = (wave1 + wave2 + wave3) / 3.0;

    // UV distortion for the live feed
    vec2 distort = vec2(
        combined * 0.05 * (1.0 + bass * 2.0),
        (wave1 - wave2) * 0.04 * (1.0 + mid * 2.0)
    );
    
    vec2 sampUV = tc + distort;

    // Chromatic aberration on the live feed
    float chroma = abs(combined) * 0.08 + treble * 0.05;
    vec3 current_col;
    current_col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    current_col.g = texture(samp, sampUV).g;
    current_col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Add acid interference and crests
    float interference = combined * 0.5 + 0.5;
    current_col *= acid(interference + time_f * 0.1 + bass) * 1.5;
    
    float crest = pow(max(combined, 0.0), 6.0);
    current_col += acid(r1 + time_f * 0.2) * crest * (1.0 + air * 2.0);

    // 3. Add Polar Spirals centered on the dynamic origin
    vec2 polarUV = uv - effectOrigin;
    float r_center = length(polarUV);
    float theta = atan(polarUV.y, polarUV.x);
    
    float spiralArms = 3.0 + floor(treble * 4.0);
    float spiralTwist = 15.0 - bass * 8.0;
    float spiralSpeed = time_f * (4.0 + amp_smooth * 8.0);
    
    float spiralPhase = theta * spiralArms - r_center * spiralTwist - spiralSpeed;
    float spiralBeams = pow(max(sin(spiralPhase), 0.0), 5.0);
    float spiralFalloff = exp(-r_center * (2.0 - mid)); 
    vec3 spiralColor = acid(r_center * 0.8 - time_f * 0.5 + mid * 0.5);
    
    current_col += spiralColor * spiralBeams * (0.6 + bass * 2.0) * spiralFalloff;
    current_col *= 0.85 + amp_smooth * 0.35;

    // 4. Ring Buffer Recursion with AGGRESSIVE Historical Audio Flow
    vec3 accum = current_col;
    float accWeight = 1.0;

    // Default procedural center
    vec2 feedbackCenter = vec2(0.5) + distort * 2.5;

    // Left Click: Direct Feedback Center Control
    if (iMouse.z > 0.0) {
        feedbackCenter = mouseUV + distort * 0.1; 
    }

    // Right Click: Zoom Control
    float userZoomShift = 0.0;
    if (iMouse.w > 0.0) {
        userZoomShift = (0.5 - mouseUV.y) * 2.5; 
    }

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        // Fetch historical data
        float h_bass   = sampleSpectrumHistory(i, 0.03);
        float h_mid    = sampleSpectrumHistory(i, 0.22);
        float h_treble = sampleSpectrumHistory(i, 0.58);
        float h_air    = sampleSpectrumHistory(i, 0.80);

        // Apply audio data and the right-click manual zoom override
        float rawZoom = 0.95 + 0.02 * sin(time_f * 0.5) - (h_bass * 0.12) + userZoomShift; 
        float h_zoomPerLayer = max(rawZoom, 0.01);
        
        float h_rotPerLayer = 0.03 * sin(time_f * 0.3) + (h_treble * 0.15);

        float zoom = pow(h_zoomPerLayer, gen);
        float rot = h_rotPerLayer * gen;
        float cs = cos(rot), sn = sin(rot);

        vec2 centered = tc - feedbackCenter;
        centered *= zoom;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
        vec2 fbUV = centered + feedbackCenter;

        vec4 cached = sampleCache(i, fbUV);

        float shift = gen * 0.05;
        
        // Locked-in deep dark purple drift
        cached.r *= 1.0 + shift * 0.2 + (h_mid * 0.1);    // Throttle red heavily to stop pink
        cached.g *= 1.0 - shift * 2.0 - (h_bass * 0.2);   // Nuke green completely
        cached.b *= 1.0 + shift * 0.9 + (h_air * 0.2);    // Let blue carry the energy
        cached.rgb *= 0.95;                               // Darken each generation slightly to avoid blowout

        float w = pow(0.78, gen); 
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // 5. Final Processing
    // Shift the black point down for a darker, moodier look
    accum = (accum - 0.5) * 1.5 + 0.4; 
    accum = clamp(accum, 0.0, 1.0);
    
    // Hard inversion glitch on absolute audio peaks
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.85, 1.0, amp_peak));

    color = vec4(accum, 1.0);
}