#version 330 core
// Gem glass — frosted glass softening at frame edges only.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 ts = 1.5 / iResolution;
    vec3 b = (texture(samp, tc + ts).rgb + texture(samp, tc - ts).rgb
            + texture(samp, tc + vec2(ts.x, -ts.y)).rgb
            + texture(samp, tc + vec2(-ts.x, ts.y)).rgb) * 0.25;
    vec2 p = tc - 0.5;
    float edge = smoothstep(0.15, 0.55, length(p));
    color = vec4(mix(c, b, edge * 1.0), 1.0);
}
