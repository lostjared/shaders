#version 330 core
in vec3 vNormal;
uniform sampler2D samp;
out vec4 color;

void main() {
    const float PI = 3.141592653589793;
    vec3 n = normalize(vNormal);
    float u = atan(n.z, n.x) / (2.0 * PI) + 0.5;
    float v = acos(clamp(n.y, -1.0, 1.0)) / PI;
    color = texture(samp, vec2(u, v));
}