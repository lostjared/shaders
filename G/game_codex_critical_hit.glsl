#version 330 core
// Critical hit: white flash, red shards, and impact ripple.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    float beat = pow(0.5 + 0.5 * sin(time_f * 10.0), 8.0);
    float shards = step(0.92, sin(atan(p.y, p.x) * 18.0 + r * 25.0 - time_f * 8.0) * 0.5 + 0.5);
    float ripple = exp(-pow((r - 0.22 - beat * 0.25) * 18.0, 2.0));
    vec3 c = texture(samp, clamp(tc - normalize(p + 1e-5) * ripple * 0.03, 0.0, 1.0)).rgb;
    c = mix(c, vec3(1.0), beat * 0.35);
    c += vec3(1.0, 0.05, 0.02) * shards * ripple * 0.9;
    color = vec4(c, 1.0);
}
