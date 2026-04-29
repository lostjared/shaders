#version 330 core
// Cosmic web — faint procedural starfield filament pattern.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 g = floor(tc * iResolution / 4.0);
    float h = hash(g);
    float twinkle = step(0.975, h) * (0.5 + 0.5 * sin(time_f * 2.0 + h * 30.0));
    vec2 p = tc - 0.5;
    float web = sin(p.x * 18.0) * sin(p.y * 18.0);
    web = smoothstep(0.70, 1.0, web) * 0.30;
    c += vec3(0.7, 0.8, 1.0) * (twinkle * 1.0 + web);
    color = vec4(c, 1.0);
}
