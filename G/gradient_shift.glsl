#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

vec3 hue(float t) {
    return clamp(vec3(abs(t * 6.0 - 3.0) - 1.0, 2.0 - abs(t * 6.0 - 2.0), 2.0 - abs(t * 6.0 - 4.0)), 0.0, 1.0);
}

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

void main(void) {
    vec2 m = iMouse.z > 0.0 ? iMouse.xy / iResolution.xy : vec2(0.5);
    float a = time_f * 0.6;
    vec2 dir = normalize(vec2(cos(a), sin(a)));
    float span = 0.2 + 0.15 * sin(time_f * 0.7);
    vec2 startP = m - dir * span;
    vec2 endP = m + dir * span;
    vec2 ab = endP - startP;
    float L = max(length(ab), 1e-4);
    vec2 u = ab / L;
    float t = clamp(dot(tc - startP, u) / L, 0.0, 1.0);
    float edge = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.92, 1.0, t));
    float w = (t - 0.5);
    float pull = (0.02 + 0.12 * uamp) * (0.5 + 0.5 * sin(time_f * 1.1));
    vec2 uv = tc + u * w * pull * (0.5 + edge);
    vec4 base = texture(samp, uv);
    vec3 c0 = hue(fract(time_f * 0.12));
    vec3 c1 = hue(fract(time_f * 0.12 + 0.5));
    vec3 grad = mix(c0, c1, t);
    float k = clamp(amp, 0.0, 1.0);
    vec3 mixed = mix(base.rgb, base.rgb * grad, k);
    color = vec4(sin(mixed * pingPong(time_f, 10.0)), base.a);
}
