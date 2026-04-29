#version 330 core
// Metal storm — random global flicker like a stormy sky, mild.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(float x) { return fract(sin(x) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float t = floor(time_f * 8.0);
    float flick = hash(t);
    float spike = step(0.85, flick);
    vec3 storm = c * (1.0 + spike * 0.55);
    float top = smoothstep(0.7, 0.0, tc.y);
    storm += vec3(0.7, 0.85, 1.10) * spike * top * 0.30;
    color = vec4(storm, 1.0);
}
