#version 330 core
// Metal coil — subtle spiraling scanlines that rotate slowly.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float a = atan(p.y, p.x);
    float r = length(p);
    float coil = sin(a * 6.0 + r * 30.0 - time_f * 0.8) * 0.5 + 0.5;
    coil = smoothstep(0.75, 1.0, coil) * 0.45;
    color = vec4(c + vec3(1.0, 0.92, 0.75) * coil, 1.0);
}
