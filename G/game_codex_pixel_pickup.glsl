#version 330 core
// Pixel pickup: temporary chunky sparkle overlay for collecting items.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(13.13, 171.7))) * 43758.5453); }

void main(void) {
    vec2 blocks = vec2(96.0, 54.0);
    vec2 b = floor(tc * blocks);
    vec2 uv = (b + 0.5) / blocks;
    vec3 c = texture(samp, uv).rgb;
    float sparkle = step(0.975, hash(b + floor(time_f * 18.0)));
    float pulse = 0.5 + 0.5 * sin(time_f * 8.0 + hash(b) * 6.283185);
    vec3 gold = vec3(1.0, 0.78, 0.18);
    c = mix(texture(samp, tc).rgb, c, 0.35);
    c += gold * sparkle * pulse;
    color = vec4(c, 1.0);
}
