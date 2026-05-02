#version 330 core
// ant_light_color_acid_ripple_spiral_ringbuffer
// Audio-reactive spirals, rippling interference, and an 8-frame recursive feedback tunnel
// EXTREME historical FFT flow

in vec2 tc;
out vec4 color;

// Live feed and cache layers
uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

// Historical FFT data (0 is now, 7 is oldest)
uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

// Uniforms
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;

// Procedural Palette
vec3 acid(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.3, 0.2, 0.2);
    return a + b * cos(TAU * (c * t + d));
}

// Helper to fetch history frames
vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0)
        return texture(samp1, uv);
    if (idx == 1)
        return texture(samp2, uv);
    if (idx == 2)
        return texture(samp3, uv);
    if (idx == 3)
        return texture(samp4, uv);
    if (idx == 4)
        return texture(samp5, uv);
    if (idx == 5)
        return texture(samp6, uv);
    if (idx == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

// Helper to fetch historical FFT data matching the cache depth
float sampleSpectrumHistory(int idx, float freq) {
    if (idx == 0)
        return texture(spectrum1, freq).r;
    if (idx == 1)
        return texture(spectrum2, freq).r;
    if (idx == 2)
        return texture(spectrum3, freq).r;
    if (idx == 3)
        return texture(spectrum4, freq).r;
    if (idx == 4)
        return texture(spectrum5, freq).r;
    if (idx == 5)
        return texture(spectrum6, freq).r;
    return texture(spectrum7, freq).r;
}

void main() {
    // 1. Extract Current Audio Data (Live Frame)
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // 2. Base Interference & Glitch Distortion (Current Frame)
    vec2 src1 = vec2(sin(time_f * 0.3) * 0.2, cos(time_f * 0.4) * 0.15);
    vec2 src2 = vec2(-sin(time_f * 0.5) * 0.15, sin(time_f * 0.3) * 0.2);
    vec2 src3 = vec2(cos(time_f * 0.2) * 0.1, -cos(time_f * 0.6) * 0.1);

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
        (wave1 - wave2) * 0.04 * (1.0 + mid * 2.0));
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

    // 3. Add Polar Spirals
    float r_center = length(uv);
    float theta = atan(uv.y, uv.x);

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

    vec2 feedbackCenter = vec2(0.5) + distort * 2.5;

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        // Fetch historical data
        float h_bass = sampleSpectrumHistory(i, 0.03);
        float h_mid = sampleSpectrumHistory(i, 0.22);
        float h_treble = sampleSpectrumHistory(i, 0.58);
        float h_air = sampleSpectrumHistory(i, 0.80);

        // EXTREME multipliers for historical data
        // Bass causes heavy inward/outward scaling pulses
        float h_zoomPerLayer = 0.95 + 0.02 * sin(time_f * 0.5) - (h_bass * 0.12);
        // Treble causes violent rotation tearing
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

        // AGGRESSIVE Acidic Hue drift per layer driven by history
        float shift = gen * 0.05;
        cached.r *= 1.0 + shift + (h_mid * 0.25);
        cached.g *= 1.0 - shift * 0.8 - (h_bass * 0.15);
        cached.b *= 1.0 + shift * 0.4 + (h_air * 0.30);

        float w = pow(0.78, gen); // Slightly higher sustain for older frames
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // 5. Final Processing
    accum = (accum - 0.5) * 1.3 + 0.5; // Stronger contrast recovery
    accum = clamp(accum, 0.0, 1.0);

    // Hard inversion glitch on absolute audio peaks
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.85, 1.0, amp_peak));

    color = vec4(accum, 1.0);
}
