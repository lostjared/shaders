#version 330 core
// Hologram: cyan tint, horizontal scan slices, occasional band drift.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    float band = floor(tc.y * 80.0);
    float drift = (hash(band + floor(time_f * 6.0)) - 0.5) * 0.02;
    vec2 uv = tc + vec2(drift, 0.0);
    vec3 c = texture(samp, uv).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 holo = mix(vec3(0.0, 0.4, 0.7), vec3(0.6, 1.0, 1.2), lum);
    float line = 0.85 + 0.15 * sin(tc.y * iResolution.y * 1.6 + time_f * 3.0);
    holo *= line;
    float flicker = 0.92 + 0.08 * hash(floor(time_f * 10.0));
    color = vec4(holo * flicker, 1.0);
}
