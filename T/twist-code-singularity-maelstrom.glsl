#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

vec2 spin(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * p;
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 scale = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * scale;
    float r = length(p);
    float a = atan(p.y, p.x);

    float rings = sin(r * 54.0 - time_f * 9.0 + sin(a * 6.0) * 2.5);
    float abyss = 1.0 / (r + 0.045);
    a += time_f * 1.15 + abyss * 1.35 + rings * 0.24;
    float rr = r + rings * 0.055 + sin(a * 11.0 - time_f * 5.0) * 0.025;
    vec2 q = spin(vec2(cos(a), sin(a)) * rr, -time_f * 0.3);
    vec2 uv = fract(q / scale * (1.0 + abyss * 0.055) + 0.5);

    vec2 tangent = vec2(-sin(a), cos(a)) / scale;
    float split = 0.003 + 0.009 * (1.0 - smoothstep(0.05, 0.75, r));
    vec3 col = vec3(texture(samp, fract(uv + tangent * split)).r,
                    texture(samp, uv).g,
                    texture(samp, fract(uv - tangent * split)).b);
    float pulse = 0.78 + 0.32 * sin(r * 72.0 - time_f * 12.0);
    color = vec4(col * pulse, texture(samp, uv).a);
}
