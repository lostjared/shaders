#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
float sharpWave(float x) {
    return sign(sin(x)) * pow(abs(sin(x)), 0.38);
}

void main(void) {
    vec2 p = tc * vec2(8.0, 6.0);
    float a = sharpWave(dot(p, vec2(1.0, 0.33)) * 2.4 - time_f * 3.2);
    float b = sharpWave(dot(p, vec2(-0.42, 1.0)) * 3.1 + time_f * 2.5);
    float fine = sin(dot(p, vec2(0.71, -0.7)) * 8.0 - time_f * 5.0);
    vec2 disp = vec2(a + fine * 0.18, b - fine * 0.16) * 0.016;
    vec4 src = texture(samp, safeUV(tc + disp));
    float foam = pow(clamp(a * b * 0.5 + 0.5, 0.0, 1.0), 13.0);
    float flash = pow(max(0.0, sin(time_f * 0.41 + 2.2)), 42.0);
    vec3 rgb = src.rgb * vec3(0.72, 0.82, 0.89);
    rgb += vec3(0.40, 0.54, 0.61) * foam * 0.35 + vec3(0.18, 0.21, 0.24) * flash;
    color = vec4(rgb, texture(samp, tc).a);
}
