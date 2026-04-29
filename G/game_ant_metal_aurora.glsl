#version 330 core
// Metal aurora — green/violet aurora ribbons drifting overhead, edge-faded.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float band = sin(tc.x * 6.0 + time_f * 0.5 + sin(tc.y * 3.0 + time_f * 0.2) * 1.5);
    band = band * 0.5 + 0.5;
    float top = smoothstep(0.7, 0.0, tc.y);
    vec3 a = mix(vec3(0.10, 0.95, 0.50), vec3(0.65, 0.30, 1.10), band);
    color = vec4(c + a * top * 0.55, 1.0);
}
