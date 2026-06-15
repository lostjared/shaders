#version 330 core
// Underwater depth: caustic wobble, blue grade, and depth haze.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 uv = tc;
    float caustic = sin(uv.x * 38.0 + sin(uv.y * 16.0 + time_f) * 3.0 + time_f * 2.0);
    caustic += sin((uv.x + uv.y) * 29.0 - time_f * 1.5);
    uv += vec2(caustic * 0.004, sin(uv.x * 22.0 + time_f * 1.7) * 0.006);
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float depth = smoothstep(0.0, 1.0, tc.y);
    c = mix(c, vec3(0.02, 0.22, 0.42), 0.38 + depth * 0.25);
    c += vec3(0.1, 0.55, 0.8) * max(0.0, caustic) * 0.07;
    color = vec4(c, 1.0);
}
