#version 330 core
// Anime-style radial speed lines from screen center.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float a = atan(v.y, v.x);
    float r = length(v);
    float spokes = 64.0;
    float idx = floor(a / (6.2831853 / spokes));
    float seed = hash(idx);
    float band = step(0.5, fract(seed * 7.0 + time_f * (0.5 + seed)));
    float reach = smoothstep(0.18, 0.55, r) * band;
    vec3 line = mix(c, vec3(1.0), reach * 0.85);
    color = vec4(line, 1.0);
}
