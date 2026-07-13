#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

vec2 mirrorRepeat(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float depth = 1.0 / (r + 0.045) + time_f * 2.0;
    float thread = sin(a * 9.0 - depth * 3.4);
    float thread2 = cos(a * 17.0 + depth * 5.1);
    float drillA = a + depth * 0.72 + thread * 0.16;
    vec2 uv = mirrorRepeat(vec2(drillA / TAU * 4.0 + thread2 * 0.06,
                                depth * 0.34 + log(r) * 0.7 + thread * 0.11));
    vec2 uv2 = mirrorRepeat(uv * vec2(0.83, 1.19) + vec2(thread, thread2) * 0.08);
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, uv2);
    float metal = pow(0.5 + 0.5 * thread, 3.0);
    vec3 rgb = mix(c0.rgb, c1.bgr, 0.32 + metal * 0.3);
    rgb *= 0.58 + metal * 0.9 + abs(thread2) * 0.2;
    color = vec4(rgb, c0.a);
}
