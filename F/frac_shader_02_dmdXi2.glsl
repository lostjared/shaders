#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 folded = p;
    for (int i = 0; i < 6; ++i) {
        folded = abs(folded) / max(dot(folded, folded), 0.18) - 0.72;
        float a = time_f * 0.08 + float(i) * 0.31;
        folded = mat2(cos(a), -sin(a), sin(a), cos(a)) * folded;
    }
    vec2 uv = fract(folded / vec2(aspect, 1.0) + 0.5);
    vec4 source = texture(samp, uv);
    float diamond = abs(folded.x) + abs(folded.y);
    vec3 glow = 0.55 + 0.45 * cos(vec3(0.0, 2.1, 4.2) + diamond * 5.0 - time_f);
    color = vec4(mix(source.rgb, source.rgb * glow * 1.8, 0.6), source.a);
}
