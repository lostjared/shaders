#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

void main(void) {
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 d = tc - m;
    float r = length(d);
    vec2 dir = d / max(r, 1e-6);

    float waveLength = 0.05;
    float amplitude = 0.02;
    float speed = 2.0;

    float ripple = sin((r / waveLength - time_f * speed) * 6.2831853);
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);
    uv = uv + dir * ripple * amplitude;
    color = texture(samp, uv);
}
