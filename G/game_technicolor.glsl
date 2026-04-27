#version 330 core
// Two-strip Technicolor (red/cyan biased).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float r = c.r;
    float gb = (c.g + c.b) * 0.5;
    vec3 strip = vec3(r * 1.10, gb * 0.95, gb * 1.05);
    strip = (strip - 0.5) * 1.10 + 0.5;
    color = vec4(clamp(strip, 0.0, 1.0), 1.0);
}
