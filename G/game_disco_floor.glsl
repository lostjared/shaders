#version 330 core
// Disco floor: animated colored tile overlay, multiplied with the source.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 hue(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main(void) {
    vec3 src = texture(samp, tc).rgb;
    vec2 cell = floor(tc * vec2(16.0, 9.0));
    float seed = hash(cell);
    float beat = step(0.5, fract(time_f * 1.5 + seed));
    vec3 tile = hue(seed + time_f * 0.2);
    vec3 mixed = src * mix(vec3(0.7), tile * 1.6, beat * 0.7);
    color = vec4(mixed, 1.0);
}
