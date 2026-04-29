#version 330 core
// Metal flux — flowing horizontal flux lines, very low contrast.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float flux = sin(tc.y * 80.0 + sin(tc.x * 4.0 + time_f * 0.6) * 2.0);
    flux = smoothstep(0.6, 1.0, flux) * 0.32;
    color = vec4(c + vec3(0.5, 0.85, 1.10) * flux, 1.0);
}
