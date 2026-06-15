#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(41.23, 289.17))) * 37158.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec2 mirrorWrap(vec2 p) {
    return abs(fract(p) * 2.0 - 1.0);
}

void main(void) {
    float t = time_f * 0.7;
    vec2 uv = tc;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 cell = floor(uv * vec2(12.0, 9.0));
    vec2 local = fract(uv * vec2(12.0, 9.0)) - 0.5;
    vec2 mouseCell = floor(mouseUV * vec2(12.0, 9.0));
    float mouseBoost = smoothstep(4.0, 0.0, distance(cell, mouseCell));
    float n = noise(cell * 0.73 + t * 0.15);
    float angle = n * 6.283185 + sin(t + cell.x * 0.4) * 0.7;
    float s = sin(angle), c = cos(angle);
    local = mat2(c, -s, s, c) * local;
    local += (mouseUV - (cell + 0.5) / vec2(12.0, 9.0)) * mouseBoost * 0.25;
    float ripple = sin(length(local) * 28.0 - t * 4.0 + n * 6.0);
    vec2 warped = (cell + local + 0.5) / vec2(12.0, 9.0);
    warped += normalize(local + 0.001) * ripple * 0.018;
    vec3 base = texture(samp, mirrorWrap(warped)).rgb;
    float grout = smoothstep(0.48, 0.42, max(abs(local.x), abs(local.y)));
    vec3 glaze = 0.5 + 0.5 * cos(vec3(0.2, 1.8, 3.9) + n * 5.0 + ripple * 1.8);
    color = vec4(mix(base * 0.22, mix(base, glaze, 0.35), grout), 1.0);
}
