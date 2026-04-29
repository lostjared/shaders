#version 330 core
// Metal ember — warm flickering ember glow on dark areas.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float dark = smoothstep(0.5, 0.05, lum);
    float fl = sin(time_f * 3.0 + hash(floor(tc * 12.0)) * 30.0) * 0.5 + 0.5;
    vec3 ember = vec3(1.0, 0.45, 0.15) * dark * fl * 0.60;
    color = vec4(c + ember, 1.0);
}
