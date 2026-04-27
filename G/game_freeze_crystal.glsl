#version 330 core
// Freeze: blue tint, reduced saturation, faceted ice tessellation distortion.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453) - 0.5;
}

void main(void) {
    vec2 g = floor(tc * 18.0);
    vec2 f = fract(tc * 18.0);
    vec2 jitter = hash2(g) * 0.3;
    vec2 facet = (f - 0.5 + jitter) * 0.012;
    vec3 c = texture(samp, tc + facet).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 ice = mix(vec3(0.55, 0.75, 1.0), vec3(0.95, 1.0, 1.05), lum);
    c = mix(c, ice, 0.55);
    float sparkle = step(0.985, fract(sin(dot(g, vec2(12.9, 78.2))) * 43758.0 + time_f));
    c += vec3(sparkle);
    color = vec4(c, 1.0);
}
