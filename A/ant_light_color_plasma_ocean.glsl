#version 330 core
// ant_light_color_plasma_ocean
// Oceanic plasma surface with cresting wave foam and deep color gradients

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 ocean(float t) {
    vec3 deep = vec3(0.02, 0.08, 0.25);
    vec3 mid_c = vec3(0.0, 0.35, 0.55);
    vec3 surface = vec3(0.3, 0.8, 0.6);
    float p = fract(t);
    vec3 c = mix(deep, mid_c, smoothstep(0.0, 0.5, p));
    return mix(c, surface, smoothstep(0.5, 1.0, p));
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

    vec2 uv = tc;

    // Ocean surface displacement with multiple wave harmonics
    float wave = 0.0;
    wave += sin(uv.x * 6.0 + iTime * 1.5 + bass * 4.0) * 0.3;
    wave += sin(uv.x * 12.0 - iTime * 2.5 + uv.y * 3.0) * 0.15 * mid;
    wave += sin(uv.x * 25.0 + iTime * 4.0) * 0.05 * treble;
    wave += noise(uv * 8.0 + iTime * 0.5) * 0.2;

    // Foam on crests
    float foam = smoothstep(0.35, 0.5, wave);
    foam += noise(uv * 30.0 + iTime) * foam * 0.5;

    // UV distortion from waves
    vec2 distort = vec2(wave * 0.03, wave * 0.02) * (1.0 + bass);
    vec2 sampUV = uv + distort;

    float chroma = treble * 0.03 + foam * 0.02;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Ocean depth color
    float depth = 1.0 - uv.y + wave * 0.5;
    col *= ocean(depth + iTime * 0.05) * 2.0;

    // Foam bright overlay
    col += vec3(0.8, 0.95, 1.0) * foam * (0.5 + air * 1.0);

    // Plasma glow underneath
    float plasma = sin(uv.x * 15.0 + iTime * 2.0) * sin(uv.y * 15.0 + iTime * 1.5);
    plasma = pow(max(plasma, 0.0), 3.0);
    col += ocean(plasma + iTime * 0.1) * plasma * (0.3 + mid * 0.5);

    // Sun reflection
    float sunY = 0.7 + sin(iTime * 0.2) * 0.1;
    float sun = exp(-length(vec2(uv.x - 0.5, uv.y - sunY)) * (8.0 - bass * 3.0));
    col += vec3(1.0, 0.9, 0.7) * sun * (1.5 + amp_peak * 3.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
