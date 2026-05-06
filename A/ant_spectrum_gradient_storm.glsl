#version 330 core
// ant_spectrum_gradient_storm
// Chaotic multi-mirror storm with rainbow lightning, echo turbulence, and gradient chaos

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
    float mid = texture(spectrum, 0.20).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.78).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Multi-mirror storm: chaotic folds
    for (int i = 0; i < 4; i++) {
        uv = abs(uv) - 0.5;
        uv *= rot(iTime * 0.15 + float(i) * 0.7 + bass * 0.5);
        uv = abs(uv);
        if (uv.y > uv.x)
            uv = uv.yx;
    }

    // Turbulent noise distortion
    float noiseStr = 0.05 + mid * 0.1;
    float nx = noise(uv * 5.0 + iTime * 0.7);
    float ny = noise(uv * 5.0 - iTime * 0.5);
    uv += vec2(nx, ny) * noiseStr;

    // Mirror-wrapped texture
    vec2 texUV = mirror(uv * 0.4 + 0.5);

    // Chromatic storm
    float split = 0.015 + treble * 0.05;
    vec3 result;
    result.r = texture(samp, mirror(texUV + vec2(split, split))).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - vec2(split, split))).b;

    // Echo turbulence
    for (float e = 1.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.1).r;
        vec2 off = vec2(noise(uv * 3.0 + e + iTime), noise(uv * 3.0 - e)) * 0.04 * e;
        vec3 echoCol = texture(samp, mirror(texUV + off)).rgb;
        echoCol *= rainbow(e * 0.25 + iTime * 0.3 + freq);
        result += echoCol * (0.3 / e);
    }

    // Lightning glow
    float lightning = pow(noise(uv * 20.0 + iTime * 5.0), 8.0);
    result += lightning * rainbow(iTime * 0.5 + hiMid) * 2.0 * bass;

    // Gradient chaos
    float dist = length(uv);
    result *= mix(vec3(1.0), rainbow(dist + iTime * 0.4), 0.3 + air * 0.2);

    // Color cycle
    result = mix(result, result.brg, smoothstep(0.3, 0.7, sin(iTime * 0.5)));

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
