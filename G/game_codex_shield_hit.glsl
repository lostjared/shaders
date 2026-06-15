#version 330 core
// Shield hit: hex energy shimmer with a pulsing blue edge flash.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    float r = length(p);
    float hex = abs(sin((p.x * 18.0 + p.y * 10.0) + time_f * 4.0));
    hex *= abs(sin((p.x * -18.0 + p.y * 10.0) - time_f * 3.2));
    float ring = exp(-pow((r - mod(time_f * 0.45, 0.9)) * 18.0, 2.0));
    vec3 c = texture(samp, tc + normalize(p + 1e-5) * ring * 0.025).rgb;
    vec3 shield = vec3(0.2, 0.75, 1.0) * (pow(hex, 10.0) * 0.45 + ring * 0.9);
    color = vec4(c + shield, 1.0);
}
