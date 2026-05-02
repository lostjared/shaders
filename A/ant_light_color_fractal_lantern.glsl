#version 330 core
// ant_light_color_fractal_lantern
// Fractal fold geometry emitting lantern-like warm light pulses

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 warmLight(float t) {
    vec3 a = vec3(0.8, 0.4, 0.1);
    vec3 b = vec3(0.3, 0.3, 0.2);
    vec3 c = vec3(1.0, 0.8, 0.5);
    vec3 d = vec3(0.0, 0.15, 0.2);
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

    // Fractal fold iterations
    vec3 glow = vec3(0.0);
    vec2 fuv = p * (2.0 + bass);
    float scale = 1.0;

    for (int i = 0; i < 7; i++) {
        fuv = abs(fuv) - 0.5 + bass * 0.1;
        fuv = rot(iTime * 0.2 + float(i) * 0.5 + mid * 0.3) * fuv;
        fuv *= 1.3;
        scale *= 1.3;

        float d = length(fuv);
        float ring = 0.015 / abs(sin(d * (6.0 + treble * 8.0) - iTime * 1.5) / 6.0);
        glow += warmLight(d * 0.3 + float(i) * 0.12 + iTime * 0.08) * ring / scale;
    }

    // Texture through fractal warp
    vec2 sampUV = fract(fuv * 0.06 + tc);
    float chroma = (mid + air) * 0.03;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    col = mix(col, col + glow * 0.4, 0.5 + mid * 0.3);

    // Lantern pulse with bass
    col *= 1.0 + bass * 0.8;
    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
