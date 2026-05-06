#version 330 core
// ant_light_color_aurora_veil
// Shimmering aurora curtains over kaleidoscope mirror with spectral color wash

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 aurora(float t) {
    vec3 a = vec3(0.1, 0.7, 0.4);
    vec3 b = vec3(0.3, 0.3, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);
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

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscope mirror
    float segments = 6.0 + floor(bass * 6.0);
    float angle = atan(uv.y, uv.x);
    float r = length(uv);
    float stepA = TAU / segments;
    angle = mod(angle, stepA);
    angle = abs(angle - stepA * 0.5);
    vec2 kUV = vec2(cos(angle), sin(angle)) * r;
    kUV.x /= aspect;
    vec2 sampUV = kUV + 0.5;

    vec3 col = texture(samp, sampUV).rgb;

    // Aurora curtain layers
    float curtain = 0.0;
    for (float i = 1.0; i < 5.0; i++) {
        float n = noise(vec2(uv.x * (3.0 + i) + iTime * (0.5 + i * 0.2), i * 5.0));
        curtain += n * (0.4 / i);
    }
    curtain *= 1.0 + mid * 2.0;

    float veil = smoothstep(0.2, 0.7, uv.y + curtain * 0.5);
    veil *= smoothstep(-0.3, 0.1, uv.y + curtain * 0.3);

    vec3 auroraCol = aurora(curtain + iTime * 0.15 + bass);
    col = mix(col, col + auroraCol * veil, 0.5 + treble * 0.3);

    // Shimmer particles on air
    float sparkle = step(0.97, hash(floor(uv * 30.0 + iTime * 2.0)));
    col += aurora(iTime + r) * sparkle * air * 3.0;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
