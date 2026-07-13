#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float warp = 0.0;
    float amp = 0.16;
    float freq = 18.0;
    for (int i = 0; i < 5; ++i) {
        float fi = float(i);
        warp += sin(r * freq - time_f * (4.0 + fi * 2.1) + a * (3.0 + fi * 2.0)) * amp;
        freq *= 1.82;
        amp *= 0.52;
    }
    float qa = a + 1.25 / r + time_f + warp;
    float depth = -log(r) + time_f * 0.85 + warp * 0.6;
    vec2 uv = vec2(fract(qa / TAU * 3.0 + depth * 0.35), fract(depth));
    vec2 uv2 = fract(uv + vec2(warp, -warp) * 0.12);
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, uv2);
    vec3 rgb = mix(c0.rgb, c1.bgr, 0.38 + 0.18 * sin(warp * 9.0));
    rgb *= 0.72 + abs(warp) * 1.8;
    color = vec4(rgb, c0.a);
}
