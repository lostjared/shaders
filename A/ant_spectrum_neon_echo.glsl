#version 330 core
// ant_spectrum_neon_echo
// Neon glow lines with mirrored echo feedback, rainbow cycling, and kaleidoscopic fold

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

void main() {
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    // Kaleidoscope
    float seg = floor(6.0 + bass * 6.0);
    uv = kaleidoscope(uv, seg);

    // Neon fractal glow with mirror folds
    vec3 neonAccum = vec3(0.0);
    for (float i = 0.0; i < 5.0; i++) {
        uv = fract(uv * (1.3 + mid * 0.3)) - 0.5;
        uv = abs(uv); // mirror fold
        uv *= rot(iTime * 0.1 + i * 0.4);

        float d = length(uv) * exp(-length(uv0));
        d = sin(d * (8.0 + hiMid * 10.0) + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.1);

        neonAccum += rainbow(length(uv0) + i * 0.2 + iTime * 0.3 + treble) * d;
    }

    // Mirrored texture echo feedback
    vec3 echoTex = vec3(0.0);
    for (float e = 0.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.1 + 0.05).r;
        vec2 echoUV = kaleidoscope(uv0 * (1.0 + e * 0.05), seg);
        echoUV = abs(echoUV);
        vec2 eTex = mirror(echoUV * 0.6 + 0.5 + vec2(sin(iTime * 0.3 + e), cos(iTime * 0.4 + e)) * 0.02 * e);
        vec3 s = texture(samp, eTex).rgb;
        s *= rainbow(e * 0.25 + freq + iTime * 0.2);
        echoTex += s * (0.35 / (1.0 + e * 0.3));
    }

    // Compose
    vec3 result = mix(echoTex, neonAccum, 0.45 + lowMid * 0.2);

    // Color cycling
    float cycle = iTime * 0.4;
    result = mix(result, result.brg, sin(cycle) * 0.5 + 0.5);

    // Gradient
    float r = length(uv0);
    result *= mix(vec3(1.0), rainbow(r + iTime * 0.25), 0.2);

    result *= 0.85 + amp_smooth * 0.3;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
