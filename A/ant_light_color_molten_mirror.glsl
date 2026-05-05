#version 330 core
// ant_light_color_molten_mirror
// Molten lava mirror reflections with heat shimmer and spectrum magma veins

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 magma(float t) {
    vec3 a = vec3(0.5, 0.1, 0.0);
    vec3 b = vec3(0.5, 0.4, 0.1);
    vec3 c = vec3(2.0, 1.0, 0.4);
    vec3 d = vec3(0.0, 0.25, 0.25);
    return a + b * cos(TAU * (c * t + d));
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

vec2 mirrorUV(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;

    // Heat shimmer distortion
    float shimmer = noise(vec2(uv.x * 5.0, uv.y * 3.0 - iTime * 2.0));
    shimmer += noise(vec2(uv.x * 10.0, uv.y * 7.0 - iTime * 3.0)) * 0.5;
    uv += shimmer * 0.02 * (1.0 + bass);

    // Mirror fold
    vec2 mUV = mirrorUV(uv * 2.0 + vec2(sin(iTime * 0.3) * 0.5, cos(iTime * 0.2) * 0.5));

    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, mUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, mUV).g;
    col.b = texture(samp, mUV - vec2(chroma, 0.0)).b;

    // Magma veins
    float vein = noise(uv * 8.0 + iTime * 0.3);
    vein = pow(abs(vein - 0.5) * 2.0, 0.5);
    vein = 1.0 - vein;
    vein = smoothstep(0.3, 0.8, vein);

    col = mix(col, col * magma(vein + iTime * 0.05 + bass), vein * (0.5 + mid * 0.4));

    // Glowing cracks
    float crack = smoothstep(0.9, 1.0, vein);
    col += magma(iTime * 0.1 + vein) * crack * (2.0 + air * 3.0);

    // Heat glow from below
    float heat = smoothstep(0.0, 1.0, 1.0 - tc.y) * (0.3 + bass * 0.5);
    col += magma(0.2) * heat * 0.5;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
