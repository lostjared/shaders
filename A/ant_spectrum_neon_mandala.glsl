#version 330 core
// ant_spectrum_neon_mandala
// Neon fractal mandala with kaleidoscopic mirroring and rainbow glow rings

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

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.10).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 uv0 = uv;

    // Mandala kaleidoscope: 8-16 segments
    float seg = floor(8.0 + bass * 8.0);
    uv = kaleidoscope(uv, seg);

    // Neon fractal rings
    vec3 neonAccum = vec3(0.0);
    for (float i = 0.0; i < 6.0; i++) {
        uv = fract(uv * (1.3 + mid * 0.4)) - 0.5;
        uv *= rot(iTime * 0.12 + i * 0.5);
        // Mirror fold
        uv = abs(uv);
        if (uv.y > uv.x) uv = uv.yx;

        float d = length(uv) * exp(-length(uv0));
        float ringFreq = 8.0 + hiMid * 10.0 + i * 1.5;
        d = sin(d * ringFreq + iTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2);

        vec3 col = rainbow(length(uv0) + i * 0.15 + iTime * 0.25 + treble);
        neonAccum += col * d;
    }

    // Texture sample through kaleidoscope
    vec2 texUV = abs(fract(uv * 0.5 + 0.5) * 2.0 - 1.0);
    vec4 tex = texture(samp, texUV);

    // Echo feedback
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.08).r;
        vec2 off = vec2(freq * 0.03 * e, 0.0) * rot(iTime + e);
        echo += texture(samp, abs(fract((texUV + off) * 0.5 + 0.5) * 2.0 - 1.0)).rgb * (0.4 / e);
    }

    // Compose
    vec3 result = mix(tex.rgb + echo * 0.3, neonAccum, 0.45 + lowMid * 0.2);

    // Gradient overlay
    float r = length(uv0);
    result *= mix(vec3(1.0), rainbow(r + iTime * 0.3), 0.25);

    // Color shifting
    result = mix(result, result.brg, smoothstep(0.3, 0.7, sin(iTime * 0.5)));

    // Brightness
    result *= 0.85 + amp_smooth * 0.35;
    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
