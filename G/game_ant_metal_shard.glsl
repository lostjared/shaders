#version 330 core
// Metal shard — angular triangular shard highlights, static, faint.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 8.0;
    vec2 g = floor(p), f = fract(p);
    float tri = step(f.x + f.y, 1.0);
    float h = hash(g + tri);
    float sh = (0.5 + 0.5 * sin(time_f * 0.8 + h * 6.0)) * step(0.55, h) * 0.40;
    color = vec4(c + vec3(0.85, 0.95, 1.10) * sh, 1.0);
}
