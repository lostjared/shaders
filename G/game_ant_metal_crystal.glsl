#version 330 core
// Metal crystal — faint angular hex highlights overlay, time-shimmer.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hex(vec2 p) {
    p = abs(p);
    return max(p.x * 0.866 + p.y * 0.5, p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = (tc - 0.5);
    p.x *= iResolution.x / iResolution.y;
    p *= 12.0;
    vec2 g = floor(p);
    vec2 f = fract(p) - 0.5;
    float h = hex(f);
    float shim = smoothstep(0.40, 0.50, h) * (0.5 + 0.5 * sin(time_f + g.x + g.y));
    color = vec4(c + vec3(0.5, 0.75, 1.10) * shim * 0.40, 1.0);
}
