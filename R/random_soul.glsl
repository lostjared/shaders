#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}
float h(float n) { return fract(sin(n) * 43758.5453123); }
vec2 h2(float n) { return vec2(h(n), h(n + 1.23)); }

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main() {
    vec2 res = iResolution;
    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= res.y / res.x;

    float t = time_f * 0.25;
    float seg = floor(t);
    float a = fract(t);
    vec2 p0 = -0.5 + h2(seg) * 1.0;
    vec2 p1 = -0.5 + h2(seg + 1.0) * 1.0;
    a = a * a * (3.0 - 2.0 * a);
    vec2 swirlC = mix(p0, p1, a);

    vec2 d = uv - swirlC;
    float r = length(d);
    float k = 0.85;
    float s = 0.45;
    float theta = k * exp(-r * 2.5) * (1.0 + 0.5 * sin(time_f * 0.6));
    float ct = cos(theta);
    float st = sin(theta);
    vec2 rot = vec2(d.x * ct - d.y * st, d.x * st + d.y * ct) + swirlC;

    float angle = atan(uv.y, uv.x) + time_f * 20.0;
    vec3 rain = rainbow(angle / (2.0 * 3.1415926535));

    float bulge_strength = 0.2;
    float distortion = pow(length(rot), 2.0) * bulge_strength;
    vec2 distorted = rot * (1.0 + distortion);

    vec2 tex = distorted * 0.5 + 0.5;
    vec4 base = texture(samp, tex);
    vec3 blend = mix(base.rgb, rain, 0.5);

    color = vec4(sin(blend * time_f), base.a);
}
