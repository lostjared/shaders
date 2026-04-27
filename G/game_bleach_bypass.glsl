#version 330 core
// Bleach-bypass film grade (desaturated highlights, crunchy contrast).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 desat = mix(vec3(lum), c, 0.55);
    desat = (desat - 0.5) * 1.30 + 0.5;
    color = vec4(clamp(desat, 0.0, 1.0), 1.0);
}
