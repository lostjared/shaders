#version 330 core
// Lost-signal radio static: heavy noise, occasional roll bar, mono mix.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float n = hash(gl_FragCoord.xy + time_f * 60.0);
    float bar = smoothstep(0.04, 0.0, abs(fract(tc.y - time_f * 0.3) - 0.5));
    vec3 mono = vec3(lum * 0.5 + n * 0.6);
    mono += bar * 0.4;
    color = vec4(mono, 1.0);
}
