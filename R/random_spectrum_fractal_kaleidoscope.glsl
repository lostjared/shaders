#version 330 core
// Remix: gem-spiral-frac (fractal fold) + gem-hue-frac (neon rings) + gem_kale_large (kaleidoscope)
// Spectrum drives: kaleidoscope segments (bass), fractal fold zoom (mid), neon glow color (treble)

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec2 kaleidoscope(vec2 p, float segments) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float step_a = 2.0 * PI / segments;
    ang = mod(ang, step_a);
    ang = abs(ang - step_a * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

void main() {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.20).r;
    float hiMid = texture(spectrum, 0.35).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    // Bass-driven kaleidoscope segments (4-12 segments)
    float segments = floor(4.0 + bass * 8.0);
    uv = kaleidoscope(uv, segments);

    // Fractal fold loop with mid-driven zoom
    vec3 neonAccum = vec3(0.0);
    float foldZoom = 1.3 + mid * 0.5;

    for (float i = 0.0; i < 5.0; i++) {
        // Fold and scale
        uv = fract(uv * foldZoom) - 0.5;
        uv *= rot(iTime * 0.15 + i * 0.5);

        float d = length(uv) * exp(-length(uv0));

        // Neon ring creation — frequency from hiMid
        float ringFreq = 6.0 + hiMid * 10.0;
        d = sin(d * ringFreq + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.1);

        // Color per layer — treble shifts the palette
        vec3 col = palette(length(uv0) + i * 0.3 + iTime * 0.3 + treble * 2.0);
        neonAccum += col * d;
    }

    // Texture distortion from fractal coordinates
    vec2 distort = uv * (0.04 + mid * 0.03);
    vec4 tex = texture(samp, tc + distort);

    // Spiral overlay driven by bass
    float p_dist = length(uv0);
    float p_angle = atan(uv0.y, uv0.x);
    float spiral = p_angle + log(p_dist + 0.001) * 2.0 - iTime * (1.0 + bass * 3.0);
    float spiralMask = smoothstep(0.2, 0.8, sin(spiral * (3.0 + bass * 4.0)));

    // Compose: texture + neon fractal with spiral masking
    vec3 result = mix(tex.rgb, neonAccum * spiralMask, 0.55 + hiMid * 0.2);

    // Air frequencies add shimmer
    result += air * 0.15 * vec3(0.6, 0.8, 1.0) * sin(iTime * 8.0 + p_dist * 20.0);

    // Peak inversion flash
    float inv = smoothstep(0.9, 1.0, amp_peak);
    result = mix(result, vec3(1.0) - result, inv);

    color = vec4(result, 1.0);
}
