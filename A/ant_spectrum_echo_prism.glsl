#version 330 core
// ant_spectrum_echo_prism
// Triple prism echo with mirror bounces, rainbow dispersion, and kaleidoscopic symmetry

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

void main() {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscope
    float seg = floor(6.0 + bass * 4.0);
    vec2 kUV = kaleidoscope(uv, seg);
    kUV = abs(kUV);

    // Triple prism: three independent chromatic paths
    float dispersion = 0.02 + treble * 0.06;
    float angle = atan(uv.y, uv.x);
    vec2 dirR = vec2(cos(angle + dispersion * 5.0), sin(angle + dispersion * 5.0));
    vec2 dirB = vec2(cos(angle - dispersion * 5.0), sin(angle - dispersion * 5.0));

    vec2 uvR = kaleidoscope(uv + dirR * dispersion, seg);
    vec2 uvB = kaleidoscope(uv + dirB * dispersion, seg);
    uvR = abs(uvR);
    uvB = abs(uvB);

    vec3 prism;
    prism.r = texture(samp, mirror(uvR * 0.6 + 0.5)).r;
    prism.g = texture(samp, mirror(kUV * 0.6 + 0.5)).g;
    prism.b = texture(samp, mirror(uvB * 0.6 + 0.5)).b;

    // Echo prism bounces
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        float edisp = dispersion * (1.0 + e * 0.3);
        vec2 eUV = kaleidoscope(uv * (1.0 + e * 0.03), seg);
        eUV = abs(eUV);
        vec3 eCol;
        eCol.r = texture(samp, mirror(eUV * 0.6 + 0.5 + vec2(edisp, 0.0))).r;
        eCol.g = texture(samp, mirror(eUV * 0.6 + 0.5)).g;
        eCol.b = texture(samp, mirror(eUV * 0.6 + 0.5 - vec2(edisp, 0.0))).b;
        eCol *= rainbow(e * 0.2 + iTime * 0.25 + mid);
        echo += eCol * (0.25 / e);
    }

    vec3 result = prism + echo;

    // Rainbow gradient
    float r = length(uv);
    result *= mix(vec3(1.0), rainbow(r * 2.0 + iTime * 0.3 + bass), 0.25 + air * 0.15);

    // Color shift
    result = mix(result, result.gbr, hiMid * 0.4);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
