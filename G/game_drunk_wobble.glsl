#version 330 core
// Slow gentle wobble. Useful for drunk/dazed status effects.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 uv = tc;
    uv.x += sin(time_f * 1.7 + uv.y * 6.0) * 0.006;
    uv.y += cos(time_f * 1.3 + uv.x * 5.0) * 0.006;
    vec3 c = texture(samp, uv).rgb;
    color = vec4(c, 1.0);
}
