#version 330 core
// Molten web — lava-like cracked pattern under-glow on dark areas.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 5.0;
    vec2 g = floor(p), f = fract(p);
    float d = 1.0;
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            vec2 o = vec2(i, j);
            float h = hash(g + o);
            vec2 r = o + vec2(0.5 + 0.5 * sin(h * 12.0 + time_f * 0.4), 0.5 + 0.5 * cos(h * 9.0 + time_f * 0.3)) - f;
            d = min(d, length(r));
        }
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float dark = smoothstep(0.6, 0.05, lum);
    float vein = smoothstep(0.10, 0.0, abs(d - 0.30)) * dark * 0.95;
    color = vec4(c + vec3(1.0, 0.45, 0.10) * vein, 1.0);
}
