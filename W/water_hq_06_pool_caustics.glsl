#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
float caustic(vec2 p) {
    float t = time_f * 0.65;
    vec2 q = p * 22.0;
    float x = sin(q.x + sin(q.y * 0.73 + t) * 2.2 + t);
    float y = sin(q.y + sin(q.x * 0.61 - t * 1.2) * 2.0 - t * 0.8);
    float z = sin((q.x + q.y) * 0.57 + t * 1.4);
    return pow(clamp(1.0 - abs(x + y + z) * 0.31, 0.0, 1.0), 5.0);
}

void main(void) {
    float e = 0.002;
    float c = caustic(tc);
    vec2 grad = vec2(caustic(tc + vec2(e, 0)) - c, caustic(tc + vec2(0, e)) - c);
    vec4 src = texture(samp, safeUV(tc + grad * 0.035));
    vec3 rgb = src.rgb * (0.92 + c * 0.30) + vec3(0.02, 0.13, 0.18) * c;
    color = vec4(rgb, texture(samp, tc).a);
}
