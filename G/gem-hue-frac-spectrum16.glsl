#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// 16 Discrete History Buffers
uniform sampler1D spectrum0; // T=0
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;
uniform sampler1D spectrum8;
uniform sampler1D spectrum9;
uniform sampler1D spectrum10;
uniform sampler1D spectrum11;
uniform sampler1D spectrum12;
uniform sampler1D spectrum13;
uniform sampler1D spectrum14;
uniform sampler1D spectrum15; // T=15 (Oldest)

// Helper to fetch from the discrete stack
float sampleHistory(int index, float freq) {
    switch (index) {
    case 0:
        return texture(spectrum0, freq).r;
    case 1:
        return texture(spectrum1, freq).r;
    case 2:
        return texture(spectrum2, freq).r;
    case 3:
        return texture(spectrum3, freq).r;
    case 4:
        return texture(spectrum4, freq).r;
    case 5:
        return texture(spectrum5, freq).r;
    case 6:
        return texture(spectrum6, freq).r;
    case 7:
        return texture(spectrum7, freq).r;
    case 8:
        return texture(spectrum8, freq).r;
    case 9:
        return texture(spectrum9, freq).r;
    case 10:
        return texture(spectrum10, freq).r;
    case 11:
        return texture(spectrum11, freq).r;
    case 12:
        return texture(spectrum12, freq).r;
    case 13:
        return texture(spectrum13, freq).r;
    case 14:
        return texture(spectrum14, freq).r;
    default:
        return texture(spectrum15, freq).r;
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