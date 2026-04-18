#version 330 core
// Spectrum Cache 4 — Waveform Feedback
// Cache frames are displaced along a sine wave whose frequency and
// amplitude are pulled from the spectrum.  The result is a feedback
// loop where the image warps and folds back on itself in sync with
// the audio, creating a liquid, oscilloscope-like trail effect.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform sampler1D spectrum;
uniform vec2 iResolution;
uniform float time_f;

vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp1, uv);
    if (idx == 1) return texture(samp2, uv);
    if (idx == 2) return texture(samp3, uv);
    if (idx == 3) return texture(samp4, uv);
    if (idx == 4) return texture(samp5, uv);
    if (idx == 5) return texture(samp6, uv);
    if (idx == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

void main(void) {
    vec4 current = texture(samp, tc);

    float bass   = texture(spectrum, 0.05).r;
    float mid    = texture(spectrum, 0.30).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.85).r;

    // Build a waveform displacement field from the spectrum
    // Bass controls vertical wave, mid controls horizontal wave
    float waveFreqX = 3.0 + treble * 12.0;
    float waveFreqY = 2.0 + mid * 10.0;
    float waveAmpX  = bass * 0.025;
    float waveAmpY  = mid * 0.020;

    vec3 accum = vec3(0.0);
    float totalW = 0.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1);
        float decay = 1.0 / (1.0 + age * 0.3);

        // Progressive waveform distortion — deeper into cache = more warp
        float phase = time_f * 1.5 + age * 0.4;
        float dx = sin(tc.y * waveFreqX + phase) * waveAmpX * age;
        float dy = cos(tc.x * waveFreqY + phase * 0.7) * waveAmpY * age;

        vec2 warped = tc + vec2(dx, dy);
        warped = clamp(warped, 0.0, 1.0);

        vec4 cached = sampleCache(i, warped);

        // Sample a per-frame spectrum slice for color modulation
        float bandPos = float(i) / 8.0;
        float bandEnergy = texture(spectrum, bandPos).r;

        float w = decay * (0.3 + bandEnergy * 0.7);
        accum += cached.rgb * w;
        totalW += w;
    }

    accum /= max(totalW, 0.001);

    // Feedback color cycling: shift hue based on bass/treble ratio
    float ratio = bass / max(bass + treble, 0.01);
    vec3 warmTint = vec3(1.1, 0.85, 0.7);
    vec3 coolTint = vec3(0.7, 0.9, 1.15);
    accum *= mix(coolTint, warmTint, ratio);

    // Edge glow on waveform peaks
    float edgeX = abs(sin(tc.y * waveFreqX + time_f * 1.5) * waveAmpX);
    float edgeY = abs(cos(tc.x * waveFreqY + time_f * 1.05) * waveAmpY);
    float edgeGlow = smoothstep(0.01, 0.0, min(edgeX, edgeY)) * air * 0.3;
    accum += edgeGlow;

    // Blend: current frame with waveform-warped feedback trails
    float feedbackMix = 0.5 + bass * 0.2;
    vec3 result = mix(current.rgb, max(current.rgb, accum), feedbackMix);

    color = vec4(result, 1.0);
}
