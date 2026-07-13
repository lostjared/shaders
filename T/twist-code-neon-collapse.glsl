#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float collapse = 1.2 / r + 5.0 * exp(-r * 4.0);
    float filament = sin(a * 15.0 + r * 80.0 - time_f * 14.0);
    a += collapse + time_f * 0.95 + filament * 0.16;
    r += filament * 0.04;
    vec2 uv = fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
    vec2 normal = vec2(cos(a), sin(a)) / ar;
    vec3 c0 = texture(samp, uv).rgb;
    vec3 c1 = texture(samp, fract(uv + normal * 0.018)).rgb;
    vec3 edge = abs(c0 - c1) * 3.5;
    vec3 neon = edge * vec3(0.35, 1.1, 1.8) + edge.bgr * vec3(1.5, 0.2, 0.75);
    float ring = 0.5 + 0.5 * sin(r * 92.0 - time_f * 16.0);
    vec3 rgb = c0 * (0.62 + ring * 0.38) + neon;
    color = vec4(rgb, texture(samp, uv).a);
}
