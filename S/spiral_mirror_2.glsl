#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

float pingPong(float x, float l) {
    float m = mod(x, l * 2.0);
    return m <= l ? m : l * 2.0 - m;
}
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    vec2 toA = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 fromA = vec2(1.0 / toA.x, 1.0);

    vec2 p = (tc * 2.0 - 1.0) * toA;
    p.x = abs(p.x);

    float r = length(p);
    float a = atan(p.y, p.x);

    float rotSpeed = 0.9;
    float zoomPeriod = 6.0;
    float zPhase = pingPong(time_f, zoomPeriod) / zoomPeriod;

    float minZ = 0.6;
    float maxZ = 2.4;
    float zoom = mix(minZ, maxZ, zPhase);

    a += time_f * rotSpeed;
    r /= zoom;

    vec2 s = vec2(cos(a), sin(a)) * r;

    vec2 q = s;
    q = rot(0.35) * q;
    for (int i = 0; i < 5; i++) {
        q = abs(q) / (dot(q, q) + 0.001) - 0.5;
        q = rot(0.25) * q;
    }

    float mixAmt = 0.55 + 0.35 * sin(time_f * 0.3);
    vec2 uv = mix(s, q, mixAmt);

    uv = uv * fromA * 0.5 + 0.5;
    color = texture(samp, uv);
}
