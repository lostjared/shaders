#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

float pp(float x, float l) {
    float m = mod(x, l * 2.0);
    return abs(m - l);
}
float s2(float x) { return x * x * (3.0 - 2.0 * x); }

void main(void) {
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);
    float a = clamp(amp, 0.0, 1.0);
    float ua = clamp(uamp, 0.0, 1.0);

    vec2 c;
    if (iMouse.z > 0.5)
        c = iMouse.xy / iResolution;
    else {
        float t = time_f * 0.3;
        c = vec2(0.5) + 0.25 * vec2(cos(t * 0.9), sin(t * 1.1)) * 0.6;
    }

    float r = length(uv - c);
    float rippleSpeed = mix(4.0, 10.0, ua);
    float rippleAmp = mix(0.01, 0.06, a);
    float rippleWave = mix(8.0, 18.0, ua);
    float ripple = sin(uv.x * rippleWave + time_f * rippleSpeed) * rippleAmp;
    ripple += sin(uv.y * rippleWave * 0.9 + time_f * rippleSpeed * 1.07) * rippleAmp;
    vec2 uv_rip = uv + vec2(ripple);

    float twist = mix(0.8, 2.2, a) * (r - 0.8) + time_f * (0.3 + ua * 0.7);
    float ca = cos(twist), sa = sin(twist);
    mat2 rot = mat2(ca, -sa, sa, ca);
    vec2 uv_twist = (rot * (uv - c)) + c;

    float w = s2(clamp(1.0 - r * 2.0, 0.0, 1.0));
    float k = mix(0.35, 0.75, ua);
    vec2 uv_mix = mix(uv_rip, uv_twist, k * w + (1.0 - k) * 0.5);

    float zoom = 1.0 + 0.02 * sin(time_f * 0.8 + ua * 2.0);
    vec2 zc = (uv_mix - c) / zoom + c;

    vec4 col0 = texture(samp, uv);
    vec4 col1 = texture(samp, zc);
    // color = mix(col0, col1, 0.7);
    color = col1;
}
