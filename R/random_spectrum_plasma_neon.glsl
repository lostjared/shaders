#version 330 core
// Remix: gem_plas (liquid noise) + gem-light-frac (neon light lines) + gem_rainbow_spectrum (mirror)
// Spectrum drives: noise frequency (bass), neon line intensity (mid), mirror axis bend (treble)

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.141592653589;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.18).r;
    float hiMid = texture(spectrum, 0.35).r;
    float treble = texture(spectrum, 0.55).r;

    vec2 uv = tc;

    // === Mirror axis from rainbow_spectrum: bass bends the axis ===
    vec2 centered = uv - 0.5;
    float mirrorBend = bass * sin(centered.y * PI + iTime * 2.0);
    centered.x += mirrorBend;
    centered.x = abs(centered.x);
    uv = centered + 0.5;

    // === Liquid plasma distortion from gem_plas: treble drives amplitude ===
    float noiseFreq = 3.0 + mid * 5.0;
    float nx = noise(uv * noiseFreq + iTime * 0.5);
    float ny = noise(uv * noiseFreq - iTime * 0.4);
    float distAmt = 0.02 + treble * 0.06;
    vec2 plasmaUV = uv + vec2(nx, ny) * distAmt;

    // === Frequency-driven ripples from rainbow_spectrum ===
    float rippleForce = hiMid * 0.08;
    plasmaUV.y += rippleForce * sin(plasmaUV.x * 20.0 + iTime * 5.0);
    plasmaUV.x += rippleForce * cos(plasmaUV.y * 20.0 + iTime * 5.0);

    // Sample with chromatic split driven by treble
    float shift = smoothstep(0.2, 0.8, treble) * 0.06;
    vec3 tex;
    tex.r = texture(samp, plasmaUV + vec2(shift, 0.0)).r;
    tex.g = texture(samp, plasmaUV).g;
    tex.b = texture(samp, plasmaUV - vec2(shift, 0.0)).b;

    // === Neon light lines from gem-light-frac ===
    vec2 fracUV = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    vec2 fracUV0 = fracUV;
    vec3 neonAccum = vec3(0.0);

    for (float i = 0.0; i < 4.0; i++) {
        fracUV = fract(fracUV * (1.3 + bass * 0.4)) - 0.5;
        float d = length(fracUV) * exp(-length(fracUV0));
        vec3 col = palette(length(fracUV0) + i * 0.4 + iTime * 0.4 + mid);
        d = sin(d * (6.0 + hiMid * 6.0) + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.1);
        neonAccum += col * d;
    }

    // Scale neon intensity by mid energy
    neonAccum *= 0.3 + mid * 0.5;

    // === Neon plasma glow from gem_plas ===
    float plasmaGlow = smoothstep(0.4, 0.7, nx) * 0.15;
    vec3 glowTint = vec3(bass, 0.6 + mid * 0.4, 0.8 + treble * 0.2);

    // === Compose ===
    vec3 result = tex + neonAccum * 0.4;
    result += plasmaGlow * glowTint;

    // Frequency glow overlay
    result += vec3(bass, mid, treble) * 0.15;

    // Peak color inversion
    if (amp_peak > 0.93) {
        result = vec3(1.0) - result;
    }

    color = vec4(result, 1.0);
}
