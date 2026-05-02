#version 330 core
// ant_light_color_kaleidoscope_blaze
// Blazing kaleidoscope with fire palette, fractal edges, and treble sparks

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;
const float PI = 3.14159265;

vec3 fire(float t) {
    vec3 a = vec3(0.5, 0.2, 0.05);
    vec3 b = vec3(0.5, 0.3, 0.1);
    vec3 c = vec3(1.0, 0.7, 0.3);
    vec3 d = vec3(0.0, 0.2, 0.3);
    return a + b * cos(TAU * (c * t + d));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    p = rot(iTime * 0.2 + bass * 2.0) * p;
    p *= 1.0 - bass * 0.3;

    // Kaleidoscope
    float segments = 8.0 + floor(mid * 8.0);
    float angle = atan(p.y, p.x);
    float r = length(p);
    float step_val = TAU / segments;
    angle = mod(angle, step_val);
    angle = abs(angle - step_val * 0.5);

    vec2 kp = vec2(cos(angle), sin(angle)) * r;

    // Fractal edge detail
    vec2 fp = kp;
    for (int i = 0; i < 4; i++) {
        fp = abs(fp) - 0.3;
        fp = rot(iTime * 0.15 + float(i) * 0.8) * fp;
    }

    kp.x /= aspect;
    vec2 sampUV = kp + 0.5;

    float chroma = (treble + air) * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Fire blaze overlay from fractal
    float blaze = length(fp);
    blaze = 0.01 / abs(sin(blaze * 10.0 - iTime * 2.0) / 10.0);
    blaze = clamp(blaze, 0.0, 3.0);
    col += fire(r + iTime * 0.1 + bass) * blaze * 0.15;

    // Treble sparks
    float spark = step(0.96, fract(sin(dot(floor(p * 25.0), vec2(12.9898, 78.233))) * 43758.5453));
    col += fire(iTime + r * 2.0) * spark * treble * 4.0;

    col *= 1.0 + bass * 0.5;
    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
