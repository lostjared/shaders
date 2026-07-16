#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

float heightField(vec2 p) {
    float t = time_f * 0.8;
    return sin(p.x * 19.0 + t) * sin(p.y * 15.0 - t * 1.3) +
           0.45 * sin((p.x + p.y) * 31.0 + t * 1.7);
}

void main(void) {
    float e = 0.0018;
    float h = heightField(tc);
    vec2 grad = vec2(heightField(tc + vec2(e, 0.0)) - h, heightField(tc + vec2(0.0, e)) - h) / e;
    vec2 offset = grad * 0.00042;
    vec4 src = texture(samp, safeUV(tc + offset));
    vec3 normal = normalize(vec3(-grad * 0.07, 1.0));
    float fresnel = pow(1.0 - normal.z, 2.5);
    float glint = pow(max(dot(normal, normalize(vec3(-0.35, 0.45, 1.0))), 0.0), 28.0);
    vec3 rgb = mix(src.rgb, vec3(0.30, 0.67, 0.78), fresnel * 0.24) + glint * 0.22;
    color = vec4(rgb, texture(samp, tc).a);
}
