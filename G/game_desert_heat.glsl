#version 330 core
// Hot desert/lava grade with shimmering heat at the bottom of the frame.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 uv = tc;
    float heat = (1.0 - tc.y) * 0.012;
    uv.x += sin(uv.y * 28.0 + time_f * 2.0) * heat;
    vec3 c = texture(samp, uv).rgb;
    c *= vec3(1.10, 0.96, 0.78);
    c = (c - 0.5) * 1.06 + 0.5;
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
