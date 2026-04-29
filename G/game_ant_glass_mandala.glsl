#version 330 core
// Glass mandala — circular faceted vignette overlay (geometric, non-distorting).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    float seg = 8.0;
    float facet = abs(mod(a, 6.2831 / seg) - 3.1416 / seg);
    float ring = smoothstep(0.10, 0.0, abs(facet - 0.2)) * smoothstep(0.65, 0.20, r);
    color = vec4(c + vec3(0.8, 0.92, 1.15) * ring * 0.55, 1.0);
}
