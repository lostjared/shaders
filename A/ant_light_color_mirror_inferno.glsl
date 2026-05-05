#version 330 core
// ant_light_color_mirror_inferno
// Mirrored fractal with inferno heat palette and bass-driven turbulence

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 inferno(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c0 = vec3(0.0, 0.0, 0.02);
    vec3 c1 = vec3(0.4, 0.05, 0.5);
    vec3 c2 = vec3(0.9, 0.3, 0.1);
    vec3 c3 = vec3(1.0, 0.95, 0.6);
    float p = t * 3.0;
    if (p < 1.0) return mix(c0, c1, p);
    if (p < 2.0) return mix(c1, c2, p - 1.0);
    return mix(c2, c3, p - 2.0);
}

vec2 mirrorUV(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
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
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Turbulence distortion
    float turb = noise(uv * 5.0 + iTime * 0.5) * bass * 0.15;
    uv += turb;

    // Fractal mirror folds
    vec2 p = uv * (2.0 + mid);
    for (int i = 0; i < 5; i++) {
        p = abs(p) - 0.6 + bass * 0.1;
        p = rot(iTime * 0.1 + float(i) * 0.7) * p;
    }

    vec2 sampUV = mirrorUV(p * 0.3 + 0.5);
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Inferno overlay based on fractal distance
    float d = length(p);
    float heat = exp(-d * 0.8) * (1.0 + bass);
    col = mix(col, col * inferno(heat), 0.4 + mid * 0.3);

    // Hot spots glow
    float hotspot = 0.01 / abs(sin(d * 8.0 - iTime * 2.0) / 8.0);
    hotspot = clamp(hotspot, 0.0, 2.0);
    col += inferno(d * 0.2 + iTime * 0.1) * hotspot * 0.2 * (1.0 + air);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
