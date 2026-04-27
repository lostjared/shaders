#version 330 core
// 6-fold kaleidoscope combat overlay (slowly rotating).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 v = tc - 0.5;
    float a = atan(v.y, v.x);
    float r = length(v);
    float seg = 3.14159 / 3.0;
    a = mod(a + time_f * 0.15, seg);
    a = abs(a - seg * 0.5);
    vec2 uv = vec2(cos(a), sin(a)) * r + 0.5;
    vec3 c = texture(samp, uv).rgb;
    color = vec4(c, 1.0);
}
