#version 330 core
// ant_spectrum_neon_butterfly
// Butterfly-wing mirror symmetry with neon fractal lines, echo wings, and rainbow veins

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.0, 0.1, 0.2);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    float bass = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    // Butterfly mirror: vertical axis with wing-curve
    float wingCurve = bass * 0.15 * sin(uv.y * PI * 3.0 + iTime * 1.5);
    uv.x = abs(uv.x + wingCurve);

    // Wing vein folds
    for (int i = 0; i < 3; i++) {
        uv = abs(uv * (1.2 + lowMid * 0.2)) - 0.3;
        uv *= rot(0.3 + float(i) * 0.2 + mid * 0.3);
    }

    // Neon vein lines
    vec3 neonAccum = vec3(0.0);
    vec2 fUV = uv;
    for (float i = 0.0; i < 5.0; i++) {
        fUV = fract(fUV * (1.3 + mid * 0.3)) - 0.5;
        fUV *= rot(iTime * 0.1 + i * 0.5);
        float d = length(fUV) * exp(-length(uv0));
        d = sin(d * (8.0 + hiMid * 8.0) + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.1);
        neonAccum += rainbow(length(uv0) + i * 0.18 + iTime * 0.3 + treble) * d;
    }

    // Mirror-wrapped texture sample
    vec2 texUV = mirror(uv * 0.5 + 0.5);
    vec3 tex = texture(samp, texUV).rgb;

    // Echo wings
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.08).r;
        vec2 wingOff = vec2(abs(uv0.x + wingCurve * (1.0 + e * 0.1)), uv0.y);
        wingOff = abs(wingOff * (1.2 + e * 0.05)) - 0.3;
        echo += texture(samp, mirror(wingOff * 0.5 + 0.5)).rgb * rainbow(e * 0.2 + freq) * (0.3 / e);
    }

    // Compose
    vec3 result = mix(tex + echo, neonAccum, 0.4 + lowMid * 0.2);

    // Color shift
    result = mix(result, result.gbr, sin(iTime * 0.6) * 0.4 + 0.4);

    // Rainbow vein glow
    float dist = length(uv0);
    result *= mix(vec3(1.0), rainbow(dist + iTime * 0.25), 0.25);

    result *= 0.85 + amp_smooth * 0.3;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
