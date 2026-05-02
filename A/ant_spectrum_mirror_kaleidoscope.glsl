#version 330 core
// ant_spectrum_mirror_kaleidoscope
// Infinite mirror box kaleidoscope with rainbow reflections and echo depth

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
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscope segments modulated by bass
    float seg = floor(4.0 + bass * 8.0);
    vec2 kUV = kaleidoscope(uv, seg);

    // Infinite mirror box: recursive abs folds
    for (int i = 0; i < 4; i++) {
        kUV = abs(kUV * (1.15 + lowMid * 0.15)) - 0.35;
        kUV *= rot(iTime * 0.06 + float(i) * 0.3);
        kUV = abs(kUV);
        if (kUV.y > kUV.x)
            kUV = kUV.yx;
    }

    // Sample with mirror wrap
    vec2 texUV = mirror(kUV * 0.5 + 0.5);

    // Chromatic split
    float spread = 0.01 + treble * 0.04;
    vec3 result;
    result.r = texture(samp, mirror(texUV + vec2(spread, 0.0))).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - vec2(spread, 0.0))).b;

    // Echo depth reflections
    for (float e = 1.0; e < 5.0; e++) {
        vec2 eKUV = kaleidoscope(uv * (1.0 + e * 0.04), seg);
        for (int i = 0; i < 4; i++) {
            eKUV = abs(eKUV * (1.15 + lowMid * 0.15 + e * 0.01)) - 0.35;
            eKUV *= rot(iTime * 0.06 + float(i) * 0.3 + e * 0.02);
            eKUV = abs(eKUV);
            if (eKUV.y > eKUV.x)
                eKUV = eKUV.yx;
        }
        vec3 s = texture(samp, mirror(eKUV * 0.5 + 0.5)).rgb;
        s *= rainbow(e * 0.18 + length(kUV) + iTime * 0.2 + hiMid);
        result += s * (0.2 / e);
    }

    // Rainbow reflection tint
    float r = length(uv);
    result *= mix(vec3(1.0), rainbow(r + length(kUV) + iTime * 0.3 + mid), 0.3 + air * 0.15);

    // Color shift
    result = mix(result, result.brg, smoothstep(0.3, 0.7, sin(iTime * 0.6)));

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
