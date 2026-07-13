#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 center = vec2(0.5) + vec2(cos(time_f * 0.41), sin(time_f * 0.53)) * 0.06;
    vec2 p = (tc - center) * ar;
    float r = length(p) + 0.002;
    float a = atan(p.y, p.x);
    float gravity = exp(-r * 2.1) / r;
    float wave = sin(r * 68.0 - time_f * 12.0 + gravity);
    a += gravity * 1.25 + time_f * 0.55;
    float rr = r * (0.76 + 0.2 * sin(time_f * 1.3)) + gravity * 0.025 + wave * 0.045;
    vec2 uv = fract(vec2(cos(a), sin(a)) * rr / ar + center);

    vec2 tangent = vec2(-sin(a), cos(a)) / ar;
    vec4 base = texture(samp, uv);
    vec3 lens = vec3(texture(samp, fract(uv + tangent * gravity * 0.004)).r,
                     base.g,
                     texture(samp, fract(uv - tangent * gravity * 0.004)).b);
    float ring = exp(-abs(r - 0.29) * 18.0) * (0.5 + 0.5 * wave);
    color = vec4(lens * (0.72 + ring * 0.75), base.a);
}
