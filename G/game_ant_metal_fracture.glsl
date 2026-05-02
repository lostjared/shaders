#version 330 core
// Metal fracture — faint static crack overlay, mostly transparent.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 6.0;
    vec2 g = floor(p), f = fract(p);
    float d = 1.0;
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            vec2 o = vec2(i, j);
            vec2 r = o + vec2(hash(g + o), hash(g + o + 7.0)) - f;
            d = min(d, dot(r, r));
        }
    float crack = smoothstep(0.005, 0.0, d - 0.02) * 0.60;
    color = vec4(c - vec3(crack) * 0.7 + vec3(0.05, 0.10, 0.20) * crack, 1.0);
}
