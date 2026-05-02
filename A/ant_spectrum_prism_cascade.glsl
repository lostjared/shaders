#version 330 core
// ant_spectrum_prism_cascade
// Cascading prism reflections with chromatic split and mirror folds

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
    float bass = texture(spectrum, 0.03).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.25).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.78).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Cascading mirror folds
    vec2 p = uv;
    for (int i = 0; i < 5; i++) {
        p = abs(p) - 0.3 - float(i) * 0.05;
        p *= rot(PI / (4.0 + bass * 2.0) + float(i) * 0.2);
        p.x = abs(p.x);
    }

    // Prism chromatic separation driven by treble
    float prismSpread = 0.02 + treble * 0.06;
    vec2 baseUV = mirror(p * 0.8 + 0.5);
    vec3 tex;
    tex.r = texture(samp, mirror(p * 0.8 + 0.5 + vec2(prismSpread, 0.0))).r;
    tex.g = texture(samp, baseUV).g;
    tex.b = texture(samp, mirror(p * 0.8 + 0.5 - vec2(prismSpread, 0.0))).b;

    // Echo cascade: layered time offsets
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 4.0; e++) {
        vec2 echoP = abs(p + vec2(sin(iTime * 0.5 + e), cos(iTime * 0.5 + e)) * 0.1 * e);
        echo += texture(samp, mirror(echoP * 0.8 + 0.5)).rgb * (0.5 / e);
    }

    vec3 result = mix(tex, echo, 0.35 + mid * 0.15);

    // Rainbow gradient based on fold distance
    float foldDist = length(p);
    vec3 grad = rainbow(foldDist + iTime * 0.4 + lowMid);
    result = mix(result, result * grad * 1.5, 0.3 + bass * 0.2);

    // Color rotation
    float shift = sin(iTime * 0.7 + mid * PI);
    result = mix(result, result.brg, shift * 0.5 + 0.5);

    // Brightness pulse
    result *= 0.9 + amp_smooth * 0.3;

    // Peak flash
    float inv = smoothstep(0.92, 1.0, amp_peak);
    result = mix(result, vec3(1.0) - result, inv);

    color = vec4(result, 1.0);
}
