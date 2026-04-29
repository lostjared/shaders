#version 330 core
// Subtle chrome wave sheen — gentle bright band sweeps across screen.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float band = sin(p.x * 4.0 + p.y * 2.0 + time_f * 0.6);
    float sheen = smoothstep(0.65, 1.0, band) * 0.55;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 chrome = mix(c, vec3(lum) * vec3(0.90, 0.97, 1.12), 0.45);
    chrome += sheen * vec3(0.9, 0.95, 1.0);
    color = vec4(chrome, 1.0);
}
