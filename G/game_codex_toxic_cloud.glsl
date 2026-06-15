#version 330 core
// Toxic cloud: green haze and bubbling procedural fog.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void main(void) {
    vec2 uv = tc;
    float n = noise(uv * 7.0 + vec2(time_f * 0.25, -time_f * 0.18));
    n += noise(uv * 17.0 - time_f * 0.2) * 0.45;
    vec3 c = texture(samp, uv + vec2(sin(n * 6.0) * 0.008, cos(n * 5.0) * 0.008)).rgb;
    vec3 toxic = vec3(0.25, 1.0, 0.08) * smoothstep(0.45, 1.15, n);
    c = mix(c, c * vec3(0.65, 1.15, 0.55) + toxic, 0.45);
    color = vec4(c, 1.0);
}
