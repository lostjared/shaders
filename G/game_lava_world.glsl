#version 330 core
// Lava-world tint with rising heat distortion at the bottom.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float heatAmt = pow(1.0 - tc.y, 1.5);
    vec2 uv = tc;
    uv.x += sin(tc.y * 30.0 + time_f * 4.0) * 0.006 * heatAmt;
    uv.y += cos(tc.x * 24.0 + time_f * 3.0) * 0.004 * heatAmt;
    vec3 c = texture(samp, uv).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 lava = mix(vec3(0.18, 0.02, 0.0), vec3(1.4, 0.8, 0.15), pow(lum, 0.8));
    c = mix(c, lava, 0.55);
    c += vec3(0.5, 0.15, 0.0) * heatAmt * 0.18;
    color = vec4(c, 1.0);
}
