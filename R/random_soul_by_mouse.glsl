#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

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

    vec2 m = iMouse.xy / res * 2.0 - 1.0;
    m.y *= -res.y / res.x;

    vec2 d = uv - m;
    float r = length(d);

    float tight = 6.0;
    float angle = atan(d.y, d.x) + r * tight + time_f * 2.0;
    float ct = cos(angle), st = sin(angle);
    vec2 rot = vec2(d.x * ct - d.y * st, d.x * st + d.y * ct) + m;

    vec3 rain = rainbow((atan(rot.y, rot.x) + time_f * 2.0) / (6.28318530718));

    float bulge = 0.2;
    float k = pow(length(rot), 2.0) * bulge;
    vec2 tex = rot * (1.0 + k) * 0.5 + 0.5;

    vec4 base = texture(samp, tex);
    vec3 mixc = mix(base.rgb, rain, 0.5);
    color = vec4(sin(mixc * time_f), base.a);
}
