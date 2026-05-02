#version 330 core
// Remix: gem_kale_large (diamond fold kaleidoscope) + gem_metal (metallic rings)
// Spectrum drives: diamond fold iterations (bass), ring pattern (mid sweep), strobe pulse (treble)
// Features a continuous spectrum sweep across the ring bands

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
    vec3 d = vec3(0.0, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

vec2 rotUV(vec2 uv, float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c) * uv;
}

vec2 diamondFold(vec2 p) {
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;
    return p;
}

vec2 reflectKaleido(vec2 p, float segments) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float step_a = 2.0 * PI / segments;
    ang = mod(ang, step_a);
    ang = abs(ang - step_a * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

void main() {
    // Sample spectrum across many bands
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.75).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // === Kaleidoscope: segments driven by bass ===
    float seg = floor(4.0 + bass * 6.0);
    vec2 kUV = reflectKaleido(uv, seg);
    kUV = diamondFold(kUV);

    // Fractal fold iterations driven by lowMid
    float foldZoom = 1.1 + lowMid * 0.3;
    for (int i = 0; i < 3; i++) {
        kUV = abs(kUV * foldZoom) - 0.5;
        kUV = rotUV(kUV, iTime * 0.12 + float(i) * 0.3 + mid * 0.5);
        kUV = diamondFold(kUV);
    }

    // Log-polar tunnel from kaleidoscoped coordinates
    float rK = length(kUV) + 0.001;
    float angK = atan(kUV.y, kUV.x);
    float tunnelDepth = iTime * (0.4 + bass * 0.8);

    float base = 1.8 + 0.2 * pingPong(iTime * 0.2, 5.0);
    float period = log(base) * pingPong(iTime * PI, 5.0);
    float k = fract((log(rK) - tunnelDepth) / max(period, 0.001));
    float rw = exp(k * max(period, 0.001));
    vec2 wrapUV = vec2(cos(angK), sin(angK)) * rw * 0.5;

    // Chromatic sample
    vec2 u0 = fract(wrapUV / vec2(aspect, 1.0) + 0.5);
    vec2 u1 = fract(wrapUV * 1.02 / vec2(aspect, 1.0) + 0.5);
    vec2 u2 = fract(wrapUV * 0.98 / vec2(aspect, 1.0) + 0.5);
    vec3 kaleido;
    kaleido.r = texture(samp, u0).r;
    kaleido.g = texture(samp, u1).g;
    kaleido.b = texture(samp, u2).b;

    // === Metallic rings: density sweeps through spectrum ===
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Each ring band samples a different spectrum position
    float ringDensity = 12.0 + mid * 25.0;
    float ripple = sin(angle * (8.0 + hiMid * 8.0) + iTime) * 0.03;
    float ringDist = r + ripple;
    float ringPattern = sin(ringDist * ringDensity - iTime * 3.0);

    // Color each ring by sampling spectrum at that ring's radius position
    float specPos = fract(ringDist * 2.0);
    float specEnergy = texture(spectrum, specPos).r;
    vec3 ringColor = palette(specPos + iTime * 0.3) * (0.5 + specEnergy);

    // Center glow from bass
    float centerGlow = exp(-r * (3.5 - bass * 2.0)) * (0.6 + bass * 0.8);

    // === Compose: kaleidoscope + ring overlay ===
    vec3 result = mix(kaleido, ringColor, 0.3 + hiMid * 0.15);
    result *= 0.85 + 0.15 * ringPattern;
    result += centerGlow * vec3(1.0, 0.85, 0.6);

    // Strobe from treble
    float strobe = 0.85 + 0.15 * sin(iTime * (15.0 + treble * 20.0));
    result *= strobe;

    // Air frequency shimmer
    result += air * 0.1 * vec3(0.5, 0.7, 1.0);

    // Vignette
    result *= 1.0 - smoothstep(0.8, 1.5, r);

    color = vec4(result, 1.0);
}
