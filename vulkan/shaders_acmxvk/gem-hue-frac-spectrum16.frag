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
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



// 16 Discrete History Buffers
layout(set = 0, binding = 3) uniform sampler1D spectrum0;  // T=0
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

// Helper to fetch from the discrete stack
float sampleHistory(int index, float freq) {
    switch(index) {
        case 0: return texture(spectrum0, freq).r;
        case 1: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(1)))).r;
        case 2: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(2)))).r;
        case 3: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(3)))).r;
        case 4: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(4)))).r;
        case 5: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(5)))).r;
        case 6: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(6)))).r;
        case 7: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(7)))).r;
        case 8: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(8)))).r;
        case 9: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(9)))).r;
        case 10: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(10)))).r;
        case 11: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(11)))).r;
        case 12: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(12)))).r;
        case 13: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(13)))).r;
        case 14: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(14)))).r;
        default: return texture(spectrum_history, vec2(freq, float(SPECTRUM_HISTORY_LAYER(15)))).r;
    }
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec3 hueShift(vec3 col, float hue) {
    const vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return col * cosAngle + cross(k, col) * sin(hue) + k * dot(k, col) * (1.0 - cosAngle);
}

void main() {
    vec2 uv = (tc - 0.5) * iResolution / min(iResolution.x, iResolution.y);
    vec2 uv0 = uv;
    
    vec3 finalCol = vec3(0.0);
    float t = time_f * 0.2;

    // Radius-to-History mapping
    // We use the distance from center to pick which buffer to sample
    float r = length(uv0);
    float historySelect = clamp(r * 15.0, 0.0, 15.0);
    int idx = int(historySelect);
    
    // Smooth interpolation between temporal slices
    float fftCurrent = sampleHistory(idx, clamp(r * 0.5, 0.0, 1.0));
    float fftNext = sampleHistory(min(idx + 1, 15), clamp(r * 0.5, 0.0, 1.0));
    float fft = mix(fftCurrent, fftNext, fract(historySelect));

    for (float i = 0.0; i < 4.0; i++) {
        uv = fract(uv * 1.5) - 0.5;

        // Inject FFT into the distance calculation
        // This causes the fractal folds to "vibrate" with the history
        float d = length(uv) * exp(-length(uv0));

        vec3 col = vec3(0.5, 0.8, 0.9);
        
        // Use audio to modulate the neon frequency
        d = sin(d * (8.0 + fft * 20.0) + t) / (8.0 + fft * 5.0);
        d = abs(d);
        d = pow(0.01 / d, 1.2);

        finalCol += col * d;
    }

    // Displacement is now driven by the temporal audio state
    float distortion = (length(finalCol.rg) + fft * 0.5) * 0.05;
    vec4 sampledColor = texture(samp, tc + distortion);

    float shiftAmt = pingPong(time_f, 5.0);
    vec3 shiftedColor = hueShift(sampledColor.rgb + (finalCol * 0.5), shiftAmt + fft);
    
    color = vec4(shiftedColor, 1.0);
}