#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    float falloff = 1.0 - smoothstep(0.04, 0.72, r);
    float twist = falloff * (0.85 + 0.18 * sin(r * 42.0 - time_f * 2.4));
    vec2 q = rot(twist + time_f * 0.08 * falloff) * p;
    vec2 tangent = normalize(vec2(-q.y, q.x) + vec2(1e-5));
    q += tangent * sin(r * 58.0 - time_f * 3.2) * 0.009 * falloff;
    vec4 src = texture(samp, safeUV(q + 0.5));
    float foam = pow(max(0.0, sin(r * 72.0 - time_f * 4.0)), 12.0) * falloff;
    vec3 rgb = mix(src.rgb, vec3(0.72, 0.91, 0.96), foam * 0.35);
    color = vec4(rgb, texture(samp, tc).a);
}
