#version 330 core
// ant_spectrum_prism_mirror
// Prism mirror hall with infinite reflections, rainbow splitting, and echo corridors

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

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Mirror hall: recursive abs folds along shifting axes
    vec2 p = uv;
    for (int i = 0; i < 6; i++) {
        p = abs(p) - vec2(0.4 + bass * 0.1, 0.3 + lowMid * 0.1);
        p *= rot(float(i) * 0.4 + iTime * 0.04);
        p = abs(p);
        // Prism fold: triangular
        if (p.x + p.y > 0.5) p = vec2(0.5 - p.y, 0.5 - p.x);
    }

    // Mirror texture
    vec2 texUV = mirror(p * 0.8 + 0.5);

    // Prism rainbow split: wide dispersion
    float dispersion = 0.015 + treble * 0.05;
    vec2 prismDir = normalize(p + 0.001);
    vec3 result;
    result.r = texture(samp, mirror(texUV + prismDir * dispersion)).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - prismDir * dispersion)).b;

    // Echo corridors
    for (float e = 1.0; e < 5.0; e++) {
        vec2 ep = uv;
        for (int i = 0; i < 6; i++) {
            ep = abs(ep) - vec2(0.4 + bass * 0.1 + e * 0.005, 0.3 + lowMid * 0.1 + e * 0.005);
            ep *= rot(float(i) * 0.4 + iTime * 0.04 + e * 0.02);
            ep = abs(ep);
            if (ep.x + ep.y > 0.5) ep = vec2(0.5 - ep.y, 0.5 - ep.x);
        }
        vec3 s = texture(samp, mirror(ep * 0.8 + 0.5)).rgb;
        s *= rainbow(e * 0.2 + length(p) + iTime * 0.2 + mid);
        result += s * (0.2 / e);
    }

    // Rainbow mirror tint
    float r = length(uv);
    result *= mix(vec3(1.0), rainbow(length(p) * 2.0 + r + iTime * 0.3), 0.3 + hiMid * 0.15);

    // Color shift
    result = mix(result, result.brg, air * 0.4);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
