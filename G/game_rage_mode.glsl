#version 330 core
// Rage mode: zoom punch-in, red overlay, RGB split, vignette.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 v = tc - 0.5;
    float zoom = 0.92 + 0.02 * sin(time_f * 8.0);
    v *= zoom;
    vec2 uv = v + 0.5;
    float k = length(v) * 0.04;
    vec2 dir = normalize(v + 1e-5);
    float r = texture(samp, uv + dir * k).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, uv - dir * k).b;
    vec3 c = vec3(r, g, b);
    c.r = min(c.r * 1.25 + 0.1, 1.4);
    c.g *= 0.85;
    c.b *= 0.85;
    float vig = smoothstep(0.85, 0.3, length(v));
    c *= vig;
    color = vec4(c, 1.0);
}
