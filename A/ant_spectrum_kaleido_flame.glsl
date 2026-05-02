#version 330 core
// ant_spectrum_kaleido_flame
// Flame-like kaleidoscope with mirror shimmer, echo tongues, and warm-to-cool rainbow

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
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Flame distortion: upward noise flow
    float flameNoise1 = noise(uv * 4.0 + vec2(0.0, -iTime * 2.0));
    float flameNoise2 = noise(uv * 6.0 + vec2(0.0, -iTime * 3.0));
    vec2 flameUV = uv;
    flameUV.x += (flameNoise1 - 0.5) * 0.08 * (1.0 + bass);
    flameUV.y += (flameNoise2 - 0.5) * 0.06;

    // Kaleidoscope
    float seg = floor(6.0 + bass * 4.0);
    vec2 kUV = kaleidoscope(flameUV, seg);
    kUV = abs(kUV);
    if (kUV.y > kUV.x)
        kUV = kUV.yx;

    // Mirror flame texture
    vec2 texUV = mirror(kUV * 0.6 + 0.5);
    vec3 tex = texture(samp, texUV).rgb;

    // Echo flame tongues
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        float eN = noise(uv * (3.0 + e) + vec2(0.0, -iTime * (1.5 + e * 0.5)));
        vec2 eFlame = uv;
        eFlame.x += (eN - 0.5) * 0.1 * e;
        eFlame.y -= e * 0.02;
        vec2 eKUV = kaleidoscope(eFlame, seg);
        eKUV = abs(eKUV);
        if (eKUV.y > eKUV.x)
            eKUV = eKUV.yx;
        vec3 s = texture(samp, mirror(eKUV * 0.6 + 0.5)).rgb;
        // Warm-to-cool rainbow tint
        s *= rainbow(e * 0.15 + uv.y + 0.5 + iTime * 0.2 + mid);
        echo += s * (0.3 / e);
    }

    vec3 result = tex + echo;

    // Flame color: warm gradient mapping
    float fireT = flameNoise1 * 0.5 + uv.y * 0.5 + 0.5;
    vec3 flameColor = rainbow(fireT * 0.8 + iTime * 0.3 + bass);
    result = mix(result, result * flameColor * 1.3, 0.3 + hiMid * 0.2);

    // Shimmer
    float shimmer = pow(flameNoise2, 3.0);
    result += shimmer * rainbow(iTime * 0.5 + treble) * 0.2;

    // Color shift
    result = mix(result, result.gbr, air * 0.35);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
