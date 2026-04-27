#version 330 core
// EMP blast: expanding shockwave ring with color invert inside the wave.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 v = tc - 0.5;
    float r = length(v);
    float wave = mod(time_f * 0.6, 1.4);
    float ring = exp(-pow((r - wave) * 14.0, 2.0));
    vec2 dir = normalize(v + 1e-5);
    vec3 c = texture(samp, tc - dir * ring * 0.04).rgb;
    if (r < wave) {
        c = mix(c, 1.0 - c, smoothstep(0.0, 0.15, wave - r) * 0.6);
    }
    c += vec3(0.4, 0.7, 1.0) * ring;
    color = vec4(c, 1.0);
}
