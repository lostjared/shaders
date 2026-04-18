#version 330 core
// Remix: gem-hue-frac (neon rings, hue shift) + gem-deep (fractal feedback) + gem_spectrum_test (FFT bar)
// Spectrum drives: hue rotation speed (bass), fractal depth (mid), FFT overlay opacity (treble)
// Creates a pulsing organism of neon fractal rings with embedded spectrum analyzer

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.0, 0.1, 0.2);
    return a + b * cos(6.28318 * (c * t + d));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid    = texture(spectrum, 0.25).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    // === Neon ring fractal from gem-hue-frac ===
    vec3 neonAccum = vec3(0.0);
    float hueShift = iTime * (0.2 + bass * 1.5);

    for (float i = 0.0; i < 6.0; i++) {
        float foldScale = 1.4 + mid * 0.3;
        uv = fract(uv * foldScale) - 0.5;
        uv *= rot(iTime * 0.1 + i * 0.4);

        float d = length(uv) * exp(-length(uv0));

        // Ring frequency varies per layer
        float ringFreq = 6.0 + lowMid * 8.0 + i * 2.0;
        d = sin(d * ringFreq + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.1);

        // HSV color with bass-driven hue rotation
        float hue = fract(hueShift + length(uv0) * 0.5 + i * 0.16);
        vec3 col = hsv2rgb(vec3(hue, 0.9, 1.0));
        neonAccum += col * d;
    }

    // === Fractal feedback sample from gem-deep ===
    vec2 fUV = uv0;
    vec2 c = vec2(0.7 + bass * 0.2, 0.3 + mid * 0.3);
    float iters = 0.0;
    for (float j = 0.0; j < 24.0; j++) {
        fUV = abs(fUV) / dot(fUV, fUV) - c;
        if (length(fUV) > 10.0) break;
        iters++;
    }
    float fractalMask = iters / 24.0;

    // Texture through fractal distortion
    vec2 distort = fUV * 0.01;
    vec4 tex = texture(samp, tc + distort);

    // === FFT bar overlay from gem_spectrum_test ===
    vec3 fftOverlay = vec3(0.0);
    if (tc.y < 0.08) {
        float idx = tc.x;
        float specVal = texture(spectrum, idx).r;
        float barH = specVal * 0.08;
        if (tc.y < barH) {
            vec3 barColor = palette(idx + iTime * 0.3);
            fftOverlay = barColor * (0.5 + treble * 0.5);
        }
    }

    // === Compose ===
    vec3 result = mix(tex.rgb, neonAccum * fractalMask, 0.5 + hiMid * 0.2);

    // Blend FFT overlay (treble controls opacity)
    float fftOpacity = 0.4 + treble * 0.6;
    result = mix(result, fftOverlay, step(0.001, length(fftOverlay)) * fftOpacity);

    // Breathing brightness from amp_smooth
    result *= 0.8 + amp_smooth * 0.4;

    // Peak inversion pulse
    float inv = smoothstep(0.88, 1.0, amp_peak);
    result = mix(result, vec3(1.0) - result, inv);

    color = vec4(result, 1.0);
}
