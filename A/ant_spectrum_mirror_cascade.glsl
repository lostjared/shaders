#version 330 core
// ant_spectrum_mirror_cascade
// Cascading zoom mirrors with rainbow depth tint, chromatic echo, and kaleidoscope

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

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = mod(ang, s);
    ang = abs(ang - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
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
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscope base
    float seg = floor(6.0 + bass * 4.0);
    vec2 kUV = kaleidoscope(uv, seg);

    // Cascading zoom layers with mirror wrap
    vec3 result = vec3(0.0);
    float totalW = 0.0;
    for (float i = 0.0; i < 8.0; i++) {
        float zoom = 1.0 + i * (0.2 + mid * 0.1);
        float rotation = i * 0.15 * (1.0 + lowMid * 0.5);
        vec2 cascadeUV = kUV * zoom;
        cascadeUV *= rot(rotation + iTime * 0.05);
        cascadeUV = abs(cascadeUV);

        vec2 texUV = mirror(cascadeUV * 0.5 + 0.5);

        // Chromatic split per layer
        float spread = (0.003 + treble * 0.008) * (i + 1.0);
        vec3 s;
        s.r = texture(samp, mirror(texUV + vec2(spread, 0.0))).r;
        s.g = texture(samp, texUV).g;
        s.b = texture(samp, mirror(texUV - vec2(spread, 0.0))).b;

        // Rainbow depth tint
        s *= rainbow(i * 0.12 + length(kUV) + iTime * 0.2);

        float w = 1.0 / (1.0 + i * 0.4);
        result += s * w;
        totalW += w;
    }
    result /= totalW;

    // Gradient wash
    float r = length(uv);
    result *= mix(vec3(1.0), rainbow(r * 2.0 + iTime * 0.3 + bass), 0.25 + air * 0.15);

    // Color cycle
    result = mix(result, result.brg, smoothstep(0.3, 0.7, sin(iTime * 0.5)));

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
