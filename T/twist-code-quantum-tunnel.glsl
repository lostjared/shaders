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
    float bands = 18.0;
    float shell = floor((-log(r) * 1.4 + time_f * 1.8) * bands) / bands;
    float sector = floor((a / TAU + 0.5) * 16.0) / 16.0;
    float jump = sin(shell * 37.0 + sector * 61.0 + time_f * 5.0);
    float qa = a + 1.1 / r + shell * 2.6 + jump * 0.22;
    vec2 uv0 = fract(vec2(qa / TAU * 3.0 + shell, shell + sector * 4.0));
    vec2 uv1 = fract(vec2(-qa / TAU * 2.0 + shell, shell * 1.17 - sector * 3.0));
    vec4 c0 = texture(samp, uv0);
    vec4 c1 = texture(samp, uv1);
    float gate = step(0.0, jump);
    vec3 rgb = mix(c0.rgb, c1.bgr, 0.3 + gate * 0.35);
    rgb *= 0.75 + 0.35 * abs(jump);
    color = vec4(rgb, c0.a);
}
