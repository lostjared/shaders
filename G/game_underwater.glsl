#version 330 core
// Subtle underwater wobble + cool blue-green tint + soft caustic shimmer.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 uv = tc;
    uv.x += sin(uv.y * 14.0 + time_f * 1.4) * 0.004;
    uv.y += sin(uv.x * 11.0 - time_f * 1.1) * 0.004;
    vec3 c = texture(samp, uv).rgb;
    c *= vec3(0.78, 1.00, 1.10);
    float caustic = 0.5 + 0.5 * sin(uv.x * 30.0 + time_f * 1.5) * sin(uv.y * 28.0 - time_f * 1.2);
    c += vec3(0.04, 0.07, 0.10) * pow(caustic, 3.0);
    vec2 v = tc - 0.5;
    c *= mix(0.7, 1.0, smoothstep(0.7, 0.05, dot(v, v)));
    color = vec4(c, 1.0);
}
