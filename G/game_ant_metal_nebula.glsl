#version 330 core
// Metal nebula — cloudy color washes drift across, very subtle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float n = sin(tc.x * 3.0 + time_f * 0.2) * 0.5 + sin(tc.y * 4.0 - time_f * 0.15) * 0.5;
    n = n * 0.5 + 0.5;
    vec3 neb = mix(vec3(0.65, 0.20, 0.95), vec3(0.20, 0.55, 1.10), n);
    color = vec4(c + neb * 0.40, 1.0);
}
