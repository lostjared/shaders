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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// ant_light_color_acid_ripple_spiral_ringbuffer
// Audio-reactive spirals, rippling interference, and an 8-frame recursive feedback tunnel
// Left Click: Direct Feedback Center Control & Directional History Stretch
// Right Click: Time-Driven Hue Flashing
// Palette: Cyber Blue
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

// Procedural Palette biased strictly for Deep Blue
vec3 acid(float t) {
    vec3 a = vec3(0.05, 0.2, 0.8); // Heavy blue base
    vec3 b = vec3(0.05, 0.2, 0.6); 
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.5, 0.2, 0.0);  // Shifted phase to bring out cyan/blue crests
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

    // Default procedural center and zero stretch
    vec2 feedbackCenter = vec2(0.5) + distort * 2.5;
    vec2 historyStretch = vec2(0.0);
    vec3 userHueShift = vec3(0.0);

    // Left Click: Direct Feedback Center Control & History Stretch
    if (iMouse.z > 0.0) {
        feedbackCenter = mouseUV + distort * 0.1; 
        historyStretch = (mouseUV - vec2(0.5)) * 0.15; 
    }

    // Right Click: Time-Driven Hue Flashing
    if (iMouse.w > 0.0) {
        // Calculate how far the mouse is dragged from the center
        float dragIntensity = length(mouseUV - vec2(0.5)) * 5.0;
        
        // Multiply by time_f so scaling the engine time scales the color strobing
        float timeDrivenHue = dragIntensity * time_f * 2.0;
        
        // Output a cascading sine/cosine wave to the RGB channels
        userHueShift.r = sin(timeDrivenHue) * 2.5;
        userHueShift.g = cos(timeDrivenHue * 0.8) * 2.5;
        userHueShift.b = sin(timeDrivenHue * 1.2) * 2.5;
    }

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        // Fetch historical data
        float h_bass   = sampleSpectrumHistory(i, 0.03);
        float h_mid    = sampleSpectrumHistory(i, 0.22);
        float h_treble = sampleSpectrumHistory(i, 0.58);
        float h_air    = sampleSpectrumHistory(i, 0.80);

        float rawZoom = 0.95 + 0.02 * sin(time_f * 0.5) - (h_bass * 0.12); 
        float h_zoomPerLayer = max(rawZoom, 0.01);
        
        float h_rotPerLayer = 0.03 * sin(time_f * 0.3) + (h_treble * 0.15);

        float zoom = pow(h_zoomPerLayer, gen);
        float rot = h_rotPerLayer * gen;
        float cs = cos(rot), sn = sin(rot);

        vec2 centered = tc - feedbackCenter;
        centered *= zoom;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
                        
        // Add the directional stretch, escalating per generation layer
        vec2 fbUV = centered + feedbackCenter + (historyStretch * gen);

        vec4 cached = sampleCache(i, fbUV);

        float shift = gen * 0.05;
        
        // Blue baseline drift mixed with the high-speed time flashing
        cached.r *= 1.0 - shift * 0.8 - (h_bass * 0.15) + (userHueShift.r * gen * 0.1);
        cached.g *= 1.0 + shift * 0.2 + (h_mid * 0.10)  + (userHueShift.g * gen * 0.1);
        cached.b *= 1.0 + shift * 1.2 + (h_air * 0.30)  + (userHueShift.b * gen * 0.1);
        
        // Very slight darkening to preserve depth
        cached.rgb *= 0.95;

        float w = pow(0.78, gen); 
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // 5. Final Processing
    accum = (accum - 0.5) * 1.5 + 0.4; 
    accum = clamp(accum, 0.0, 1.0);
    
    // Hard inversion glitch on absolute audio peaks
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.85, 1.0, amp_peak));

    color = vec4(accum, 1.0);
}