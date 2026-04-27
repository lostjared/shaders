#version 330 core
// 2.39:1 cinema letterbox with mild warm grade for cutscenes.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    float bar = (1.0 - (aspect / 2.39)) * 0.5;
    if (tc.y < bar || tc.y > 1.0 - bar) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    vec3 c = texture(samp, tc).rgb;
    c = (c - 0.5) * 1.1 + 0.5;
    c *= vec3(1.06, 1.00, 0.93);
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
