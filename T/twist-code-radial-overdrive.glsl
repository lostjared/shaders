#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float w0 = sin(r * 34.0 - time_f * 7.0);
    float w1 = sin(r * 71.0 + a * 7.0 - time_f * 13.0);
    float w2 = cos(r * 143.0 - a * 11.0 + time_f * 19.0);
    float wave = w0 * 0.06 + w1 * 0.035 + w2 * 0.017;
    a += 1.0 / r + time_f * 1.15 + w1 * 0.22;
    r += wave;
    vec2 uv = fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
    vec2 kick = vec2(cos(a), sin(a)) / ar * wave;
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv + kick * 1.8));
    vec3 rgb = mix(c0.rgb, c1.rgb, 0.52);
    rgb *= 0.68 + 0.22 * w0 + 0.22 * w1 + 0.18 * w2 + 0.55;
    color = vec4(rgb, c0.a);
}
