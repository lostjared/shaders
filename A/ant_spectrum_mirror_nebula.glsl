#version 330 core
// ant_spectrum_mirror_nebula
// Nebula cloud mirror with kaleidoscopic folds, echo wisps, and gradient color bands

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
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscopic nebula folds
    float seg = floor(5.0 + bass * 5.0);
    vec2 kUV = kaleidoscope(uv, seg);
    kUV = abs(kUV);

    // Nebula noise distortion
    float nFreq = 3.0 + mid * 4.0;
    float n1 = noise(kUV * nFreq + iTime * 0.3);
    float n2 = noise(kUV * nFreq * 1.5 - iTime * 0.4);
    kUV += vec2(n1, n2) * (0.05 + hiMid * 0.05);

    // Mirror texture sample
    vec2 texUV = mirror(kUV * 0.7 + 0.5);
    vec3 tex = texture(samp, texUV).rgb;

    // Nebula echo wisps
    vec3 wisps = vec3(0.0);
    for (float e = 0.0; e < 5.0; e++) {
        float noiseOff = noise(kUV * (2.0 + e) + iTime * 0.2 * (e + 1.0));
        vec2 wispUV = mirror(kUV * 0.7 + 0.5 + vec2(noiseOff) * 0.05 * (e + 1.0));
        vec3 w = texture(samp, wispUV).rgb;
        w *= rainbow(e * 0.18 + noiseOff + iTime * 0.2);
        wisps += w * (0.25 / (1.0 + e * 0.3));
    }

    vec3 result = tex + wisps;

    // Nebula color bands
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    vec3 nebulaBand = rainbow(angle / PI + r * 1.5 + iTime * 0.2 + bass);
    float bandMask = smoothstep(0.3, 0.7, n1);
    result = mix(result, result * nebulaBand * 1.3, 0.3 * bandMask + treble * 0.2);

    // Color shift
    result = mix(result, result.gbr, smoothstep(0.4, 0.8, mid));

    // Glow
    result += exp(-r * 3.0) * rainbow(iTime * 0.5) * 0.15;
    result += air * 0.08 * vec3(0.5, 0.6, 1.0);

    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
