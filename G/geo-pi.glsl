
#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}


void main(void) {
    vec2 uv = tc * iResolution / vec2(iResolution.y);
    float time = pingPong(time_f * PI, 10) *  0.5;
    float time_t = mod(time_f, 10.0);
    float angle = time;
    vec2 center = vec2(0.5, 0.5) * iResolution / vec2(iResolution.y);
    vec2 toCenter = uv - center;
    float radius = length(toCenter);
    float theta = atan(toCenter.y, toCenter.x) + time;
    float pattern = abs(sin(12.0 * theta) * cos(12.0 * radius * (pingPong(time_f * PI, 20.0))));
    vec3 colorShift = vec3(0.5 * sin(time) + 0.5, 0.5 * cos(time) + 0.5, sin(radius - (pingPong(time * PI, 10.0))));
    vec3 finalColor = (0.2 + 0.8 * pattern) + colorShift * pattern;
    vec4 text_color = texture(samp, tc);
    vec4 fc = vec4(finalColor, 1.0);
    color = mix(text_color, fc, 0.3);
}
