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
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define slider1 ext.custom_uniforms[5].x
#define slider2 ext.custom_uniforms[5].y
#define slider3 ext.custom_uniforms[5].z
#define slider4 ext.custom_uniforms[5].w
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// ant_light_ultimate_recursive_echo_glitch
// Merges radial audio-history propagation with an 8-frame recursive feedback tunnel
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

// Live feed and 8-frame cache layers
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




// Audio variables







// Sliders from Shader 2 for physical wave control





const float TAU = 6.28318530718;

// Procedural Palette with added Hue Offset (Shader 1)
vec3 acid(float t, float hueOffset) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.3, 0.2, 0.2) + vec3(hueOffset, hueOffset * 1.2, hueOffset * 0.8);
    return a + b * cos(TAU * (c * t + d));
}

// Helper to fetch history frames (Shader 1)
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

// Pick a history buffer by integer index (Shader 2 style mapping)
float sampleEcho(int index, float freq) {
    if (index <= 0) return texture(spectrum0, freq).r;
    if (index == 1) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (index == 2) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (index == 3) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (index == 4) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (index == 5) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (index == 6) return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

// Broadband energy of a single history shell
float shellEnergyAt(int index) {
    float e = 0.0;
    e += sampleEcho(index, 0.05);
    e += sampleEcho(index, 0.20);
    e += sampleEcho(index, 0.55);
    e += sampleEcho(index, 0.90);
    return e * 0.25;
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = iMouse.xy / iResolution.xy;

    // 1. Setup Dynamic Origin and Global Hue Shift
    float globalHueShift = 0.0;
    vec2 effectOrigin = vec2(0.0);
    
    if (iMouse.w > 0.0) {
        globalHueShift = (mouseUV.x - 0.5) * 3.0;
    }
    if (iMouse.z > 0.0) {
        effectOrigin = (mouseUV - 0.5) * vec2(aspect, 1.0);
    }

    vec2 polarUV = uv - effectOrigin;
    float r = length(polarUV);
    float angle = atan(polarUV.y, polarUV.x);

    // 2. Spatial Audio History Mapping (ECHOMAP)
    float historySelect = clamp(r * 7.0, 0.0, 7.0);
    int echoIdx = int(historySelect);
    float echoFrac = fract(historySelect);

    float freqBin = clamp(r * 0.5, 0.0, 1.0);
    float fftA = sampleEcho(echoIdx, freqBin);
    float fftB = sampleEcho(min(echoIdx + 1, 7), freqBin);
    float fft = mix(fftA, fftB, echoFrac);

    float energyA = shellEnergyAt(echoIdx);
    float energyB = shellEnergyAt(min(echoIdx + 1, 7));
    float shellEnergy = mix(energyA, energyB, echoFrac);
    float audioGate = clamp(amp_rms + amp_peak + amp_low + amp_mid + amp_high, 0.0, 1.0);

    // 3. Outward Propagating Interference Waves
    float lobes = floor(mix(2.0, 40.0, max(slider1, 0.1)));
    float audioPhase = (amp_low + amp_mid) * TAU + time_f * 0.4 * audioGate;
    
    float ripple = sin(angle * lobes + audioPhase) * (amp_low * 0.08);
    float secondaryLobes = floor(lobes * 2.5);
    ripple += sin(angle * secondaryLobes - audioPhase * 2.0) * (amp_high * 0.05);

    float waveDensity = mix(5.0, 50.0, max(slider2, 0.1));
    float scrollSpeed = 2.0 * (audioGate + amp_peak * 1.5) + 0.15;
    
    float wave = sin(r * waveDensity 
                     - time_f * scrollSpeed 
                     + historySelect * 1.2 
                     + ripple * 10.0 
                     + fft * 12.0 * max(slider4, 0.1)) 
                 * (shellEnergy * 1.8 + audioGate * 0.25);

    // 4. Live Frame Chromatic Aberration & UV Distortion
    float shiftMult = mix(0.1, 5.0, max(slider3, 0.1));
    float shift = (ripple * 0.5 + wave * 0.05 + fft * 0.05 * max(slider4, 0.1)) 
                * shiftMult * (audioGate + shellEnergy);

    // Use the physical outward wave to violently distort the live UVs
    vec2 liveDistort = polarUV * (wave * 0.1 + ripple * 0.2);
    vec2 sampUV = tc + liveDistort;

    float r_chan = texture(samp, sampUV + vec2(shift, 0.0)).r;
    float g_chan = texture(samp, sampUV).g;
    float b_chan = texture(samp, sampUV - vec2(shift, 0.0)).b;
    vec3 current_col = vec3(r_chan, g_chan, b_chan);

    // 5. Acid Core Glow based on dynamic origin
    float lightRadius = 6.0 - amp_smooth * 4.0 - amp_rms * 3.0;
    float center = exp(-r * max(lightRadius, 0.5));
    current_col += acid(time_f * 0.2, globalHueShift) * center * (1.5 + amp_peak * 2.0);

    // 6. Ring Buffer Recursion (Driven by spatial FFT map)
    vec3 accum = current_col;
    float accWeight = 1.0;

    vec2 feedbackCenter = (iMouse.z > 0.0) ? (mouseUV + liveDistort * 0.2) : (vec2(0.5) + liveDistort * 1.5);
    float userZoomShift = (iMouse.w > 0.0) ? (0.5 - mouseUV.y) * 1.6 : 0.0;

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        // Fetch temporal history for the recursive zoom
        float h_bass   = sampleEcho(i, 0.03);
        float h_treble = sampleEcho(i, 0.58);
        
        // Modulate recursion zoom/rotation based on the outward wave energy
        float rawZoom = 0.95 + 0.02 * sin(time_f * 0.5) - (h_bass * 0.12) + userZoomShift + (wave * 0.02); 
        float zoom = pow(max(rawZoom, 0.01), gen);
        
        float h_rotPerLayer = 0.03 * sin(time_f * 0.3) + (h_treble * 0.15) + (ripple * 0.1);
        float rot = h_rotPerLayer * gen;
        float cs = cos(rot), sn = sin(rot);

        vec2 centered = tc - feedbackCenter;
        centered *= zoom;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
        vec2 fbUV = centered + feedbackCenter;

        vec4 cached = sampleCache(i, fbUV);

        // Tint the cached frames using the acid palette, mapped to the history shell
        float shellBlend = shellEnergyAt(i);
        vec3 genTint = acid(historySelect * 0.125 + float(i) * 0.1 - time_f * 0.1, globalHueShift);
        cached.rgb = mix(cached.rgb, cached.rgb * genTint * 2.0, shellBlend * 0.5);

        float w = pow(0.78, gen); 
        accum += cached.rgb * w;
        accWeight += w;
    }
    
    accum /= accWeight;
    accum = clamp((accum - 0.5) * 1.3 + 0.5, 0.0, 1.0);

    // 7. Additive Vivid Rings on top of the recursive glitch tunnel
    float ringPhase = r * waveDensity * 0.15915494 + historySelect * 0.18 + fft * 0.4 * max(slider4, 0.1);
    vec3 ringColor = clamp((acid(ringPhase, globalHueShift) - 0.25) * 1.8, 0.0, 1.0);
    float ringMask = smoothstep(-0.2, 0.8, wave);
    float ringStrength = ringMask * (shellEnergy * 4.0 + audioGate * 1.2 + 0.15);
    
    vec3 vivid = ringColor * ringStrength * 2.5;
    
    // Screen blend the rings over the recursive tunnel
    vec3 finalColor = 1.0 - (1.0 - accum) * (1.0 - clamp(vivid, 0.0, 1.0)); 
    finalColor += ringColor * ringStrength * 1.5; // Additive pop

    // Glitch wave feedback inversion on absolute peaks
    finalColor = mix(finalColor, vec3(1.0) - finalColor, smoothstep(0.85, 1.0, amp_peak));

    color = vec4(finalColor, 1.0);
}