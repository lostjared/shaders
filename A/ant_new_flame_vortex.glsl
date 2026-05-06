#version 330 core
// ant_new_flame_vortex
// Mix of ant_spectrum_kaleido_flame + ant_gem_prism_vortex:
// flame-like kaleidoscope distortion running through a polar tunnel
// with chromatic prism split and bass-driven zoom.

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

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Flame noise drift (upward) modulated by bass
    float n1 = noise(uv * 4.0 + vec2(0.0, -iTime * 2.0));
    float n2 = noise(uv * 7.0 + vec2(0.0, -iTime * 3.0));
    uv.x += (n1 - 0.5) * 0.10 * (1.0 + bass);
    uv.y += (n2 - 0.5) * 0.08;

    // Polar tunnel
    float dist = length(uv);
    float ang = atan(uv.y, uv.x);
    float zoom = iTime * (0.4 + bass * 0.8);
    vec2 tunnel = vec2(ang / PI + iTime * 0.05, 1.0 / (dist + 0.01) + zoom);

    // Kaleidoscope on the polar-warped angle
    float seg = floor(6.0 + mid * 8.0);
    float k = 2.0 * PI / seg;
    float kAng = abs(mod(ang, k) - k * 0.5);
    vec2 petal = vec2(cos(kAng), sin(kAng)) * dist;

    vec2 sampUV = mix(
        abs(fract(tunnel * 0.5) * 2.0 - 1.0),
        fract(petal * 0.6 + 0.5),
        0.45 + hiMid * 0.35);

    // Chromatic split driven by treble + air
    float chroma = (treble + air) * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Warm flame gradient
    float fireT = n1 * 0.5 + (uv.y * 0.5 + 0.5);
    vec3 flame = rainbow(fireT * 0.8 + iTime * 0.3 + bass);
    col = mix(col, col * flame * 1.3, 0.35 + hiMid * 0.25);

    // Shimmer sparks
    col += pow(n2, 3.0) * rainbow(iTime * 0.5 + treble) * 0.25;

    // Tunnel vignette opens with bass
    col *= smoothstep(1.6, 0.3 + bass * 0.4, dist);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
